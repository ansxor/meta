import { chmodSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { saveState } from "./config.ts";
import type { ShadowRepo } from "./shadow.ts";
import type { HarnessConfig, HarnessState, SideEffect } from "./types.ts";

const ACTIVATION_PATTERNS: RegExp[] = [
	/\bscripts\/switch\.sh\b/,
	/\bswitch-to-configuration\b/,
	/\bnixos-rebuild\b[^\n;&|]*\b(?:switch|test|boot)\b/,
];

export function isActivationCommand(command: string): boolean {
	return ACTIVATION_PATTERNS.some((pattern) => pattern.test(command));
}

export interface GateDeps {
	pi: ExtensionAPI;
	ctx: ExtensionContext;
	cwd: string;
	config: HarnessConfig;
	shadow: ShadowRepo;
	state: HarnessState;
}

export interface GateResult {
	block?: true;
	reason?: string;
	/** Rewritten command for the bash tool; never contains a password. */
	command?: string;
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`;
}

function describeReversal(command: string): string {
	if (/\bnixos-rebuild\s+(?:switch|test|boot)\b/.test(command) || /scripts\/switch\.sh/.test(command)) {
		if (/\bswitch-to-configuration\b/.test(command)) {
			return "switch back to the previous generation (`sudo nixos-rebuild switch --rollback`) and restart affected services";
		}
		if (/\bnixos-rebuild\s+boot\b/.test(command)) {
			return "boot the previous generation from the boot menu, or `sudo nixos-rebuild boot --rollback`";
		}
		if (/\bnixos-rebuild\s+test\b/.test(command)) {
			return "reboot, or switch back to the current system; test activation is not persistent";
		}
		return "`sudo nixos-rebuild switch --rollback`, or choose the previous generation in the boot menu; Flatpaks installed by the switch may also need removal";
	}
	return "switch back to the previous system generation";
}

async function commandPath(pi: ExtensionAPI, cwd: string, name: string): Promise<string | null> {
	// Non-login: keep the PATH the user launched Pi with, where their sudo/zenity live.
	const result = await pi.exec("bash", ["-c", `command -v ${name}`], { cwd, timeout: 15_000 });
	const path = result.stdout.trim().split("\n")[0];
	// Require a real executable path; a shell function or alias would make the sudo shim recurse.
	return result.code === 0 && path.startsWith("/") ? path : null;
}

async function latestDiffSummary(deps: GateDeps): Promise<string> {
	const lines: string[] = [];
	const recent = deps.state.diffs.slice(-deps.config.diffCount);
	for (const diff of recent) {
		const files = diff.files.length > 4 ? `${diff.files.slice(0, 4).join(", ")}, …` : diff.files.join(", ");
		lines.push(`- ${diff.kind} ${diff.at}: ${files || "(no files)"}`);
	}
	if (deps.state.startCommit) {
		try {
			const livePaths = await deps.shadow.changedFilesInWorktree(deps.state.startCommit);
			if (livePaths.length > 0) {
				const live = await deps.shadow.diffStat(
					deps.state.startCommit,
					undefined,
					livePaths.map((entry) => entry.path),
				);
				if (live) lines.push("", "Changes since this request started:", live);
			}
		} catch {
			// A live stat is advisory; the dialog can still open.
		}
	}
	return lines.length > 0 ? lines.join("\n") : "(no shadow diffs yet)";
}

function questionText(command: string, diffSummary: string): string {
	const clipped = command.length > 1600 ? `${command.slice(0, 1600)}\n…` : command;
	return [
		"config-harness intercepted an activation command.",
		"",
		"Command:",
		clipped,
		"",
		"Shadow diff summary:",
		diffSummary,
		"",
		"Approving runs the command with sudo -A and a Zenity password prompt (only if sudo needs credentials).",
		"Denying blocks the command. Nothing is run on deny, timeout, or close.",
	].join("\n");
}

async function confirmWithZenity(deps: GateDeps, text: string): Promise<{ approved: boolean; reason?: string }> {
	const zenity = await commandPath(deps.pi, deps.cwd, "zenity");
	if (!zenity) {
		return {
			approved: false,
			reason:
				"config-harness: zenity is not installed or not on PATH, so activation cannot be confirmed. It is declared in home/answer/packages/desktop.nix and appears after the next activation; for this first activation, run Pi inside `nix shell nixpkgs#zenity` or install pkgs.zenity manually. Do not bypass the gate.",
		};
	}
	if (!process.env.DISPLAY && !process.env.WAYLAND_DISPLAY) {
		return {
			approved: false,
			reason:
				"config-harness: no DISPLAY or WAYLAND_DISPLAY is available for the Zenity confirmation dialog. Run Pi from a graphical session. Do not bypass the gate.",
		};
	}
	const timeoutSeconds = Math.max(30, Math.ceil(deps.config.switch.timeoutMs / 1000));
	const dialogTimeout = timeoutSeconds + 15;
	const result = await deps.pi.exec(
		"timeout",
		[
			String(dialogTimeout),
			zenity,
			"--question",
			"--no-markup",
			`--title=${deps.config.switch.title}`,
			`--text=${text}`,
			`--timeout=${timeoutSeconds}`,
			"--width=760",
		],
		{ cwd: deps.cwd, timeout: (dialogTimeout + 5) * 1000 },
	);
	if (result.code === 0) return { approved: true };
	const detail =
		result.code === 124
			? "the dialog timed out"
			: "the dialog was closed or cancelled";
	return {
		approved: false,
		reason: `config-harness: activation denied (${detail}). Do not retry or bypass the gate; ask the user.`,
	};
}

interface SudoHelpers {
	binDir: string;
	askpass: string;
}

async function ensureSudoHelpers(deps: GateDeps): Promise<{ helpers?: SudoHelpers; reason?: string }> {
	const sudoPath = await commandPath(deps.pi, deps.cwd, "sudo");
	if (!sudoPath) {
		return {
			reason: "config-harness: sudo was not found on PATH; cannot run the approved activation command.",
		};
	}
	const zenityPath = await commandPath(deps.pi, deps.cwd, "zenity");
	if (!zenityPath) {
		return {
			reason:
				"config-harness: zenity is not installed, so the sudo askpass prompt cannot be shown. Install pkgs.zenity (declared in home/answer/packages/desktop.nix) or run Pi inside `nix shell nixpkgs#zenity`, then retry.",
		};
	}
	const runtime = join(deps.cwd, deps.config.runtimeDir);
	const binDir = join(runtime, "bin");
	mkdirSync(binDir, { recursive: true });

	const sudoShim = join(binDir, "sudo");
	writeFileSync(
		sudoShim,
		`#!/bin/sh\n# config-harness: make script-internal sudo use the Zenity askpass.\nfor arg in "$@"; do\n  if [ "$arg" = "-A" ]; then exec ${shellQuote(sudoPath)} "$@"; fi\ndone\nexec ${shellQuote(sudoPath)} -A "$@"\n`,
		{ encoding: "utf8", mode: 0o700 },
	);
	chmodSync(sudoShim, 0o700);

	const askpass = join(runtime, "askpass");
	writeFileSync(
		askpass,
		`#!/bin/sh\n# config-harness: print the password from Zenity to sudo. Never captured or logged.\nexec ${shellQuote(zenityPath)} --password --timeout=${Math.max(30, Math.ceil(deps.config.switch.timeoutMs / 1000))} --title=${shellQuote("config-harness: sudo password")}\n`,
		{ encoding: "utf8", mode: 0o700 },
	);
	chmodSync(askpass, 0o700);

	return { helpers: { binDir, askpass } };
}

function addSudoToBareActivation(command: string): string {
	const delimiter = String.raw`(^|(?:&&|\|\||;|\|)\s*)`;
	const withRebuild = command.replace(new RegExp(`${delimiter}(nixos-rebuild\\b)`, "g"), "$1sudo -A $2");
	return withRebuild.replace(new RegExp(`${delimiter}(switch-to-configuration\\b)`, "g"), "$1sudo -A $2");
}

export async function gateActivationCommand(command: string, toolCallId: string, deps: GateDeps): Promise<GateResult> {
	if (!isActivationCommand(command)) return {};

	const diffSummary = await latestDiffSummary(deps);
	const confirmation = await confirmWithZenity(deps, questionText(command, diffSummary));
	if (!confirmation.approved) {
		return { block: true, reason: confirmation.reason ?? "config-harness: activation denied." };
	}

	const helperResult = await ensureSudoHelpers(deps);
	if (!helperResult.helpers) {
		return { block: true, reason: helperResult.reason ?? "config-harness: cannot prepare sudo askpass." };
	}

	const effect: SideEffect = {
		command,
		at: new Date().toISOString(),
		toolCallId,
		reversal: describeReversal(command),
	};
	deps.state.sideEffects = [...deps.state.sideEffects, effect].slice(-20);
	saveState(deps.cwd, deps.config, deps.state);

	const rewritten = addSudoToBareActivation(command);
	const helpers = helperResult.helpers;
	const prefix = [
		`export PATH=${shellQuote(helpers.binDir)}:"$PATH"`,
		`export SUDO_ASKPASS=${shellQuote(helpers.askpass)}`,
		"export SUDO_ASKPASS_REQUIRE=force",
	].join("; ");
	return { command: `${prefix}; ${rewritten}` };
}
