import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isDeniedPath, truncateBytes } from "./config.ts";
import type { HarnessConfig } from "./types.ts";

export interface ChangedPath {
	status: string;
	path: string;
}

export class ShadowRepo {
	private snapshotQueue: Promise<unknown> = Promise.resolve();

	constructor(
		private readonly pi: ExtensionAPI,
		private readonly cwd: string,
		private readonly config: HarnessConfig,
	) {}

	private get gitDir(): string {
		return join(this.cwd, this.config.shadowDir);
	}

	private async git(args: string[], timeout = 60_000): Promise<{ stdout: string; stderr: string; code: number }> {
		const result = await this.pi.exec(
			"git",
			["--git-dir", this.gitDir, "--work-tree", this.cwd, "-c", "core.hooksPath=/dev/null", ...args],
			{ cwd: this.cwd, timeout },
		);
		return { stdout: result.stdout, stderr: result.stderr, code: result.code };
	}

	private async gitOrThrow(args: string[], timeout = 60_000): Promise<string> {
		const result = await this.git(args, timeout);
		if (result.code !== 0) {
			throw new Error(`git ${args[0]} failed: ${result.stderr.trim() || `exit ${result.code}`}`);
		}
		return result.stdout;
	}

	async ensure(): Promise<void> {
		mkdirSync(this.gitDir, { recursive: true });
		if (!existsSync(join(this.gitDir, "HEAD"))) {
			// init refuses --work-tree without --git-dir; create the bare repo by path instead.
			const result = await this.pi.exec("git", ["init", "--bare", "--quiet", this.gitDir], {
				cwd: this.cwd,
				timeout: 60_000,
			});
			if (result.code !== 0) {
				throw new Error(`git init failed: ${result.stderr.trim() || `exit ${result.code}`}`);
			}
		}
		this.writeExcludes();
		if (!(await this.hasHead())) {
			await this.snapshot("baseline", "shadow repository created");
		}
	}

	private writeExcludes(): void {
		const patterns = [
			".pi/shadow.git/",
			".pi/config-harness/",
			".pi/compaction.md",
			"result",
			"result-*",
			".direnv/",
			".hm-backup/",
			"node_modules/",
			"*.qcow2",
			"*.raw",
			...this.config.secretDenyPatterns,
		];
		const unique = [...new Set(patterns.map((pattern) => pattern.replace(/^\.\//, "")))];
		mkdirSync(join(this.gitDir, "info"), { recursive: true });
		writeFileSync(join(this.gitDir, "info", "exclude"), `${unique.join("\n")}\n`, "utf8");
	}

	async hasHead(): Promise<boolean> {
		const result = await this.git(["rev-parse", "--verify", "--quiet", "HEAD"]);
		return result.code === 0;
	}

	async head(): Promise<string> {
		return (await this.gitOrThrow(["rev-parse", "HEAD"])).trim();
	}

	async snapshot(kind: string, detail: string): Promise<string> {
		const run = async (): Promise<string> => {
			await this.gitOrThrow(["add", "-A"], 120_000);
			if (await this.hasHead()) {
				const staged = await this.git(["diff", "--cached", "--quiet", "HEAD"]);
				if (staged.code === 0) return this.head();
			}
			const message = `config-harness ${kind}: ${detail}`.slice(0, 500);
			await this.gitOrThrow(
				[
					"-c",
					"commit.gpgsign=false",
					"-c",
					"user.name=config-harness",
					"-c",
					"user.email=config-harness@localhost",
					"commit",
					"--allow-empty",
					"--no-verify",
					"--quiet",
					"-m",
					message,
				],
				120_000,
			);
			return this.head();
		};
		// Parallel tool results can snapshot at once; git's index cannot.
		const result = this.snapshotQueue.then(run, run);
		this.snapshotQueue = result.catch(() => undefined);
		return result;
	}

	async changedFiles(from: string, to: string): Promise<ChangedPath[]> {
		const stdout = await this.gitOrThrow(["diff", "--name-status", "--no-renames", from, to]);
		return this.parseNameStatus(stdout).filter((entry) => !isDeniedPath(entry.path, this.config.secretDenyPatterns));
	}

	async changedFilesInWorktree(from: string): Promise<ChangedPath[]> {
		const stdout = await this.gitOrThrow(["diff", "--name-status", "--no-renames", from]);
		return this.parseNameStatus(stdout).filter((entry) => !isDeniedPath(entry.path, this.config.secretDenyPatterns));
	}

	private parseNameStatus(stdout: string): ChangedPath[] {
		const entries: ChangedPath[] = [];
		for (const line of stdout.split("\n")) {
			if (!line.trim()) continue;
			const parts = line.split("\t");
			if (parts.length < 2) continue;
			entries.push({ status: parts[0], path: parts[parts.length - 1] });
		}
		return entries;
	}

	async diffStat(from: string, to?: string, paths?: readonly string[]): Promise<string> {
		const args = to ? ["diff", "--stat", "--no-color", from, to] : ["diff", "--stat", "--no-color", from];
		if (paths && paths.length > 0) args.push("--", ...paths);
		return (await this.gitOrThrow(args)).trim();
	}

	async diffPatch(from: string, to: string | undefined, maxBytes: number, paths?: readonly string[]): Promise<string> {
		const args = to
			? ["diff", "--no-color", "--no-ext-diff", "--text", from, to]
			: ["diff", "--no-color", "--no-ext-diff", "--text", from];
		if (paths && paths.length > 0) args.push("--", ...paths);
		const stdout = await this.gitOrThrow(args, 120_000);
		return truncateBytes(stdout, maxBytes).text;
	}

	async sameAsCommit(commit: string, path: string): Promise<boolean> {
		const result = await this.git(["diff", "--quiet", commit, "--", path]);
		return result.code === 0;
	}

	async saveRef(name: string, commit: string): Promise<void> {
		await this.gitOrThrow(["update-ref", name, commit]);
	}

	async checkoutPath(commit: string, path: string): Promise<void> {
		await this.gitOrThrow(["checkout", commit, "--", path], 120_000);
	}

	deletePath(path: string): void {
		rmSync(join(this.cwd, path), { force: true, recursive: false });
	}
}
