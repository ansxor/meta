import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import {
	DEFAULT_CONFIG,
	emptyState,
	HARD_DENY_PATTERNS,
	type HarnessConfig,
	type HarnessState,
} from "./types.ts";

export interface LoadedConfig {
	config: HarnessConfig;
	warnings: string[];
}

function asPositiveInt(value: unknown, fallback: number, name: string, warnings: string[]): number {
	if (typeof value !== "number" || !Number.isSafeInteger(value) || value <= 0) {
		if (value !== undefined) warnings.push(`${name} must be a positive integer; using ${fallback}`);
		return fallback;
	}
	return value;
}

function asString(value: unknown, fallback: string, name: string, warnings: string[]): string {
	if (typeof value !== "string" || value.trim() === "") {
		if (value !== undefined) warnings.push(`${name} must be a non-empty string; using ${fallback}`);
		return fallback;
	}
	return value;
}

function asStringArray(value: unknown, fallback: string[], name: string, warnings: string[]): string[] {
	if (!Array.isArray(value) || value.some((item) => typeof item !== "string" || item.trim() === "")) {
		if (value !== undefined) warnings.push(`${name} must be an array of non-empty strings; using defaults`);
		return [...fallback];
	}
	return value.map((item) => item.trim());
}

function mergeConfig(raw: unknown, warnings: string[]): HarnessConfig {
	if (!raw || typeof raw !== "object") {
		if (raw !== undefined) warnings.push("config must be a JSON object; using defaults");
		return structuredClone(DEFAULT_CONFIG);
	}
	const obj = raw as Record<string, unknown>;
	const check = obj.check && typeof obj.check === "object" ? (obj.check as Record<string, unknown>) : {};
	const sw = obj.switch && typeof obj.switch === "object" ? (obj.switch as Record<string, unknown>) : {};
	const recall = obj.recall && typeof obj.recall === "object" ? (obj.recall as Record<string, unknown>) : {};
	const deny = asStringArray(obj.secretDenyPatterns, DEFAULT_CONFIG.secretDenyPatterns, "secretDenyPatterns", warnings);

	return {
		vitalFiles: asStringArray(obj.vitalFiles, DEFAULT_CONFIG.vitalFiles, "vitalFiles", warnings),
		vitalFilesMaxBytes: asPositiveInt(
			obj.vitalFilesMaxBytes,
			DEFAULT_CONFIG.vitalFilesMaxBytes,
			"vitalFilesMaxBytes",
			warnings,
		),
		notesFile: asString(obj.notesFile, DEFAULT_CONFIG.notesFile, "notesFile", warnings),
		notesMaxBytes: asPositiveInt(obj.notesMaxBytes, DEFAULT_CONFIG.notesMaxBytes, "notesMaxBytes", warnings),
		diffCount: asPositiveInt(obj.diffCount, DEFAULT_CONFIG.diffCount, "diffCount", warnings),
		diffMaxBytes: asPositiveInt(obj.diffMaxBytes, DEFAULT_CONFIG.diffMaxBytes, "diffMaxBytes", warnings),
		shadowDir: asString(obj.shadowDir, DEFAULT_CONFIG.shadowDir, "shadowDir", warnings),
		runtimeDir: asString(obj.runtimeDir, DEFAULT_CONFIG.runtimeDir, "runtimeDir", warnings),
		check: {
			command: asString(check.command, DEFAULT_CONFIG.check.command, "check.command", warnings),
			enabled: typeof check.enabled === "boolean" ? check.enabled : DEFAULT_CONFIG.check.enabled,
			timeoutMs: asPositiveInt(check.timeoutMs, DEFAULT_CONFIG.check.timeoutMs, "check.timeoutMs", warnings),
		},
		switch: {
			timeoutMs: asPositiveInt(sw.timeoutMs, DEFAULT_CONFIG.switch.timeoutMs, "switch.timeoutMs", warnings),
			title: asString(sw.title, DEFAULT_CONFIG.switch.title, "switch.title", warnings),
		},
		recall: {
			defaultLimit: asPositiveInt(
				recall.defaultLimit,
				DEFAULT_CONFIG.recall.defaultLimit,
				"recall.defaultLimit",
				warnings,
			),
			maxLimit: asPositiveInt(recall.maxLimit, DEFAULT_CONFIG.recall.maxLimit, "recall.maxLimit", warnings),
		},
		// The hard deny list cannot be removed by configuration.
		secretDenyPatterns: [...new Set([...HARD_DENY_PATTERNS, ...deny])],
	};
}

export function configPath(cwd: string): string {
	return join(cwd, ".pi", "config-harness.json");
}

export function loadConfig(cwd: string): LoadedConfig {
	const path = configPath(cwd);
	const warnings: string[] = [];
	if (!existsSync(path)) {
		warnings.push(`${relative(cwd, path)} is missing; using built-in defaults`);
		return { config: structuredClone(DEFAULT_CONFIG), warnings };
	}
	try {
		const raw: unknown = JSON.parse(readFileSync(path, "utf8"));
		return { config: mergeConfig(raw, warnings), warnings };
	} catch (error) {
		warnings.push(`cannot read ${relative(cwd, path)}: ${error instanceof Error ? error.message : String(error)}`);
		return { config: structuredClone(DEFAULT_CONFIG), warnings };
	}
}

export function statePath(cwd: string, config: HarnessConfig): string {
	return join(cwd, config.runtimeDir, "state.json");
}

export function loadState(cwd: string, config: HarnessConfig): HarnessState {
	const path = statePath(cwd, config);
	try {
		const raw: unknown = JSON.parse(readFileSync(path, "utf8"));
		if (!raw || typeof raw !== "object") return emptyState();
		const obj = raw as Partial<HarnessState>;
		return {
			version: 1,
			baseline: typeof obj.baseline === "string" ? obj.baseline : undefined,
			startCommit: typeof obj.startCommit === "string" ? obj.startCommit : undefined,
			lastEnd: typeof obj.lastEnd === "string" ? obj.lastEnd : undefined,
			lastGuard: typeof obj.lastGuard === "string" ? obj.lastGuard : undefined,
			diffs: Array.isArray(obj.diffs) ? obj.diffs.filter(isDiffRecord) : [],
			sideEffects: Array.isArray(obj.sideEffects) ? obj.sideEffects.filter(isSideEffect) : [],
			lastCheck: isLastCheck(obj.lastCheck) ? obj.lastCheck : undefined,
			lastBlocked: isBlockedInfo(obj.lastBlocked) ? obj.lastBlocked : undefined,
			notesAppendix: typeof obj.notesAppendix === "string" ? obj.notesAppendix : undefined,
		};
	} catch {
		return emptyState();
	}
}

function isDiffRecord(value: unknown): value is HarnessState["diffs"][number] {
	if (!value || typeof value !== "object") return false;
	const v = value as Record<string, unknown>;
	return (
		typeof v.id === "string" &&
		(v.kind === "human" || v.kind === "agent" || v.kind === "agent-rolled-back") &&
		typeof v.at === "string" &&
		typeof v.from === "string" &&
		typeof v.to === "string" &&
		Array.isArray(v.files) &&
		v.files.every((f) => typeof f === "string") &&
		typeof v.stat === "string" &&
		typeof v.patch === "string"
	);
}

function isSideEffect(value: unknown): value is HarnessState["sideEffects"][number] {
	if (!value || typeof value !== "object") return false;
	const v = value as Record<string, unknown>;
	return typeof v.command === "string" && typeof v.at === "string" && typeof v.reversal === "string";
}

function isLastCheck(value: unknown): value is NonNullable<HarnessState["lastCheck"]> {
	if (!value || typeof value !== "object") return false;
	const v = value as Record<string, unknown>;
	return typeof v.command === "string" && typeof v.at === "string" && typeof v.code === "number" && typeof v.ok === "boolean" && typeof v.summary === "string";
}

function isBlockedInfo(value: unknown): value is NonNullable<HarnessState["lastBlocked"]> {
	if (!value || typeof value !== "object") return false;
	const v = value as Record<string, unknown>;
	return (
		typeof v.why === "string" &&
		typeof v.needs === "string" &&
		typeof v.ref === "string" &&
		typeof v.at === "string" &&
		Array.isArray(v.restored) &&
		v.restored.every((item) => typeof item === "string") &&
		Array.isArray(v.conflicts) &&
		v.conflicts.every((item) => typeof item === "string") &&
		Array.isArray(v.sideEffects) &&
		v.sideEffects.every(isSideEffect)
	);
}

export function saveState(cwd: string, config: HarnessConfig, state: HarnessState): void {
	const path = statePath(cwd, config);
	mkdirSync(dirname(path), { recursive: true });
	const tmp = `${path}.${process.pid}.tmp`;
	writeFileSync(tmp, `${JSON.stringify(state, null, 2)}\n`, "utf8");
	renameSync(tmp, path);
}

export function writeFileAtomic(path: string, content: string): void {
	mkdirSync(dirname(path), { recursive: true });
	const tmp = `${path}.${process.pid}.tmp`;
	writeFileSync(tmp, content, "utf8");
	renameSync(tmp, path);
}

export function appendDebug(cwd: string, config: HarnessConfig, event: string, data: unknown): void {
	if (process.env.CONFIG_HARNESS_DEBUG !== "1") return;
	try {
		const path = join(cwd, config.runtimeDir, "debug.jsonl");
		mkdirSync(dirname(path), { recursive: true });
		const line = `${JSON.stringify({ at: new Date().toISOString(), event, data })}\n`;
		writeFileSync(path, line, { encoding: "utf8", flag: "a" });
	} catch {
		// Debug logging must never break a request.
	}
}

export function resolveInside(cwd: string, relativePath: string): string | null {
	if (isAbsolute(relativePath)) return null;
	const absolute = resolve(cwd, relativePath);
	const rel = relative(cwd, absolute);
	if (rel === "" || rel === ".." || rel.startsWith(`..${sep}`)) return null;
	return absolute;
}

export function toPosixPath(path: string): string {
	return path.split(sep).join("/");
}

function escapeRegExp(value: string): string {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function globToRegExp(glob: string): RegExp {
	let source = "^";
	for (let i = 0; i < glob.length; i++) {
		const char = glob[i];
		if (char === "*") {
			if (glob[i + 1] === "*") {
				i++;
				if (glob[i + 1] === "/") {
					i++;
					source += "(?:.*/)?";
				} else {
					source += ".*";
				}
			} else {
				source += "[^/]*";
			}
		} else if (char === "?") {
			source += "[^/]";
		} else {
			source += escapeRegExp(char);
		}
	}
	return new RegExp(`${source}$`);
}

/**
 * Hard deny: checked for both context injection and shadow snapshots. A config
 * entry can add patterns, never remove these.
 */
export function isDeniedPath(relativePath: string, patterns: readonly string[]): boolean {
	const path = toPosixPath(relativePath).replace(/^\.\//, "");
	const basename = path.slice(path.lastIndexOf("/") + 1);
	for (const pattern of patterns) {
		const normalized = toPosixPath(pattern).replace(/^\.\//, "");
		if (!normalized.includes("/")) {
			if (globToRegExp(normalized).test(basename)) return true;
			continue;
		}
		if (globToRegExp(normalized).test(path)) return true;
	}
	return false;
}

export function byteLength(text: string): number {
	return Buffer.byteLength(text, "utf8");
}

export function truncateBytes(text: string, maxBytes: number): { text: string; truncated: boolean } {
	if (byteLength(text) <= maxBytes) return { text, truncated: false };
	const marker = `\n… [truncated at ${maxBytes} bytes]`;
	const markerBytes = byteLength(marker);
	if (maxBytes <= markerBytes) {
		return {
			text: Buffer.from(marker, "utf8").subarray(0, Math.max(0, maxBytes)).toString("utf8").replace(/\uFFFD+$/u, ""),
			truncated: true,
		};
	}
	const buffer = Buffer.from(text, "utf8").subarray(0, Math.max(0, maxBytes - markerBytes));
	let sliced = buffer.toString("utf8");
	sliced = sliced.replace(/\uFFFD+$/u, "");
	return { text: `${sliced}${marker}`, truncated: true };
}
