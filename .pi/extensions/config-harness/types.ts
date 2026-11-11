export interface CheckSettings {
	command: string;
	enabled: boolean;
	timeoutMs: number;
}

export interface SwitchSettings {
	/** Milliseconds the Zenity confirmation may stay open. */
	timeoutMs: number;
	title: string;
}

export interface RecallSettings {
	defaultLimit: number;
	maxLimit: number;
}

export interface HarnessConfig {
	/** Re-read on every model request, in this order (least-edited first). */
	vitalFiles: string[];
	/** Hard cap for all injected vital-file content. */
	vitalFilesMaxBytes: number;
	/** Model-maintained notes file, relative to the project root. */
	notesFile: string;
	notesMaxBytes: number;
	/** Number of most recent diffs shown in context. */
	diffCount: number;
	/** Cap for the rendered diff block. */
	diffMaxBytes: number;
	shadowDir: string;
	runtimeDir: string;
	check: CheckSettings;
	switch: SwitchSettings;
	recall: RecallSettings;
	/** Extra path patterns whose contents must never enter model context or shadow snapshots. */
	secretDenyPatterns: string[];
}

export interface DiffRecord {
	id: string;
	kind: "human" | "agent" | "agent-rolled-back";
	at: string;
	from: string;
	to: string;
	files: string[];
	stat: string;
	patch: string;
}

export interface SideEffect {
	command: string;
	at: string;
	toolCallId?: string;
	exitCode?: number;
	isError?: boolean;
	reversal: string;
}

export interface LastCheck {
	command: string;
	at: string;
	code: number;
	ok: boolean;
	summary: string;
	skipped?: boolean;
}

export interface BlockedInfo {
	why: string;
	needs: string;
	ref: string;
	at: string;
	restored: string[];
	conflicts: string[];
	sideEffects: SideEffect[];
}

export interface LastExchange {
	user: string;
	assistant: string;
	at: string;
}

export interface HarnessState {
	version: 1;
	/** First shadow commit for this worktree. */
	baseline?: string;
	/** Snapshot taken when the current user request began. */
	startCommit?: string;
	/** Snapshot taken after the last completed request. */
	lastEnd?: string;
	/** Most recent guard snapshot (after an agent tool call). */
	lastGuard?: string;
	diffs: DiffRecord[];
	sideEffects: SideEffect[];
	lastCheck?: LastCheck;
	lastBlocked?: BlockedInfo;
	/** Exact appendix last written by the harness; used to replace it without touching model notes. */
	notesAppendix?: string;
}

export const HARD_DENY_PATTERNS = [
	"*.env",
	"*.key",
	"*.age",
] as const;

export const DEFAULT_CONFIG: HarnessConfig = {
	vitalFiles: [
		"flake.nix",
		"hosts/crystalheart/default.nix",
		"modules/nixos/common.nix",
		"home/answer/default.nix",
		"home/answer/dotfiles.nix",
		"README.md",
	],
	vitalFilesMaxBytes: 60 * 1024,
	notesFile: ".pi/compaction.md",
	notesMaxBytes: 4 * 1024,
	diffCount: 3,
	diffMaxBytes: 12 * 1024,
	shadowDir: ".pi/shadow.git",
	runtimeDir: ".pi/config-harness",
	check: {
		command: "./scripts/check.sh",
		enabled: true,
		timeoutMs: 600_000,
	},
	switch: {
		timeoutMs: 60_000,
		title: "config-harness: activate NixOS configuration",
	},
	recall: {
		defaultLimit: 20,
		maxLimit: 50,
	},
	secretDenyPatterns: [...HARD_DENY_PATTERNS],
};

export function emptyState(): HarnessState {
	return { version: 1, diffs: [], sideEffects: [] };
}
