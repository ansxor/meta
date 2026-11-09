import { existsSync, readFileSync } from "node:fs";
import { resolveInside, truncateBytes, writeFileAtomic } from "./config.ts";
import type { HarnessConfig, HarnessState, SideEffect } from "./types.ts";

const HARNESS_START = "<!-- config-harness:start -->";
const HARNESS_END = "<!-- config-harness:end -->";

const DEFAULT_NOTES = `# Config harness notes

Keep this file under the configured cap (4 KB by default). It is the only
conversation state carried across requests: record the current goal, decisions,
files changed, and next steps. Do not paste large command output here.

`;

export function notesPath(cwd: string, config: HarnessConfig): string | null {
	return resolveInside(cwd, config.notesFile);
}

export function readNotes(cwd: string, config: HarnessConfig): string {
	const path = notesPath(cwd, config);
	if (!path || !existsSync(path)) return DEFAULT_NOTES;
	try {
		return readFileSync(path, "utf8");
	} catch {
		return DEFAULT_NOTES;
	}
}

export function ensureNotesFile(cwd: string, config: HarnessConfig): void {
	const path = notesPath(cwd, config);
	if (!path || existsSync(path)) return;
	writeFileAtomic(path, DEFAULT_NOTES);
}

/**
 * Remove the exact harness appendix previously written, leaving model text
 * untouched. If the model edited inside the appendix, the edited text no
 * longer matches and is preserved as model notes; a fresh appendix is added.
 */
export function modelNotesFromRaw(raw: string, previousAppendix: string | undefined): string {
	const without = previousAppendix && raw.includes(previousAppendix) ? raw.replace(previousAppendix, "") : raw;
	return without.trimEnd();
}

function oneLine(value: string, max = 220): string {
	const collapsed = value.replace(/\s+/g, " ").trim();
	return collapsed.length > max ? `${collapsed.slice(0, max - 1)}…` : collapsed;
}

function formatSideEffect(effect: SideEffect): string {
	const result =
		effect.isError === true
			? "command failed"
			: typeof effect.exitCode === "number"
				? `exit ${effect.exitCode}`
				: "result unknown";
	return `- \`${oneLine(effect.command, 160)}\` — approved ${effect.at} (${result}). Reverse: ${oneLine(effect.reversal)}`;
}

export function renderHarnessBlock(state: HarnessState): string {
	const lines: string[] = [HARNESS_START, "### Harness state", ""];

	if (state.lastCheck) {
		const check = state.lastCheck;
		lines.push(
			`- Last check: \`${oneLine(check.command, 120)}\` at ${check.at} — ${check.ok ? "passed" : `FAILED (exit ${check.code})`}.`,
		);
		if (check.summary.trim()) lines.push("", "```text", truncateBytes(check.summary.trim(), 1200).text, "```");
	} else {
		lines.push("- Last check: not run yet.");
	}

	if (state.sideEffects.length > 0) {
		lines.push("", "Irreversible side effects (approved by the user):");
		for (const effect of state.sideEffects.slice(-3)) lines.push(formatSideEffect(effect));
	} else {
		lines.push("- Irreversible side effects: none recorded.");
	}

	if (state.lastBlocked) {
		const blocked = state.lastBlocked;
		lines.push(
			"",
			`Blocked request at ${blocked.at}: ${oneLine(blocked.why)}`,
			`Needs from user: ${oneLine(blocked.needs)}`,
			`Failed work saved to shadow ref \`${blocked.ref}\`.`,
		);
		if (blocked.restored.length > 0) lines.push(`Restored: ${blocked.restored.join(", ")}`);
		if (blocked.conflicts.length > 0) lines.push(`Left in place (changed outside the agent): ${blocked.conflicts.join(", ")}`);
	}

	lines.push(
		"",
		"_This appendix is written by config-harness. Put your own notes above it; edits here may be preserved as notes and duplicated._",
		HARNESS_END,
	);
	// Keep the harness appendix from crowding out the model's notes.
	return truncateBytes(lines.join("\n"), 2000).text;
}

export function harnessBlockFor(config: HarnessConfig, state: HarnessState): string {
	return truncateBytes(renderHarnessBlock(state), Math.max(128, Math.min(2000, config.notesMaxBytes - 8))).text;
}

export function renderNotes(modelNotes: string, state: HarnessState, config: HarnessConfig): string {
	const block = harnessBlockFor(config, state);
	const blockBytes = Buffer.byteLength(block, "utf8");
	const budget = Math.max(0, config.notesMaxBytes - blockBytes - 3);
	const model = truncateBytes(modelNotes.trimEnd(), budget).text;
	return `${model}\n\n${block}\n`;
}

/** Rewrite the notes file: preserve model text, replace the exact previous harness appendix. */
export function updateNotesFile(cwd: string, config: HarnessConfig, state: HarnessState): string {
	const path = notesPath(cwd, config);
	const raw = readNotes(cwd, config);
	const model = modelNotesFromRaw(raw, state.notesAppendix);
	const rendered = renderNotes(model, state, config);
	state.notesAppendix = harnessBlockFor(config, state);
	if (path) writeFileAtomic(path, rendered);
	return rendered;
}
