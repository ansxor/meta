import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateBytes } from "./config.ts";
import type { RecallSettings } from "./types.ts";

interface RawEntryText {
	id: string;
	at: string;
	kind: string;
	text: string;
}

function contentToText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	const parts: string[] = [];
	for (const raw of content) {
		if (typeof raw !== "object" || raw === null) continue;
		const type = "type" in raw && typeof raw.type === "string" ? raw.type : "";
		if (type === "text" && "text" in raw && typeof raw.text === "string") {
			parts.push(raw.text);
		} else if (type === "image") {
			parts.push("[image]");
		} else if (type === "thinking" && "thinking" in raw && typeof raw.thinking === "string") {
			parts.push(`[thinking] ${raw.thinking}`);
		} else if (type === "toolCall" || type === "tool_call") {
			const name =
				"name" in raw && typeof raw.name === "string"
					? raw.name
					: "toolName" in raw && typeof raw.toolName === "string"
						? raw.toolName
						: "tool";
			const input = "arguments" in raw ? raw.arguments : "input" in raw ? raw.input : undefined;
			parts.push(`[tool call ${name}${input === undefined ? "" : ` ${JSON.stringify(input)}`}]`);
		}
	}
	return parts.join("\n");
}

function messageToText(value: unknown): string {
	if (typeof value !== "object" || value === null) return typeof value === "string" ? value : "";
	if ("summary" in value && typeof value.summary === "string") return value.summary;
	if ("output" in value && typeof value.output === "string") {
		const command = "command" in value && typeof value.command === "string" ? `$ ${value.command}\n` : "";
		return `${command}${value.output}`;
	}
	if ("content" in value) return contentToText(value.content);
	return "";
}

function entryToText(entry: unknown): Omit<RawEntryText, "id" | "at"> | null {
	if (typeof entry !== "object" || entry === null) return null;
	const type = "type" in entry && typeof entry.type === "string" ? entry.type : "";
	if (type === "message" && "message" in entry && typeof entry.message === "object" && entry.message !== null) {
		const message = entry.message;
		const role = "role" in message && typeof message.role === "string" ? message.role : "message";
		return { kind: role, text: messageToText(message) };
	}
	if (type === "compaction" && "summary" in entry && typeof entry.summary === "string") {
		return { kind: "compaction", text: entry.summary };
	}
	if (type === "branch_summary" && "summary" in entry && typeof entry.summary === "string") {
		return { kind: "branch-summary", text: entry.summary };
	}
	if (type === "custom_message" && "content" in entry) {
		const custom = "customType" in entry && typeof entry.customType === "string" ? entry.customType : "custom";
		return { kind: `custom:${custom}`, text: contentToText(entry.content) };
	}
	return null;
}

function snippet(text: string, query: string): string {
	const normalized = text.replace(/\s+/g, " ").trim();
	if (!query) return normalized.slice(0, 700);
	const index = normalized.toLowerCase().indexOf(query.toLowerCase());
	if (index === -1) return normalized.slice(0, 700);
	const start = Math.max(0, index - 240);
	const end = Math.min(normalized.length, index + query.length + 360);
	return `${start > 0 ? "…" : ""}${normalized.slice(start, end)}${end < normalized.length ? "…" : ""}`;
}

export function recallRawHistory(
	ctx: ExtensionContext,
	query: string | undefined,
	limitInput: number | undefined,
	settings: RecallSettings,
): string {
	const limit = Math.min(
		settings.maxLimit,
		Math.max(1, Number.isSafeInteger(limitInput) && limitInput ? limitInput : settings.defaultLimit),
	);
	const entries = ctx.sessionManager.getEntries();
	const collected: RawEntryText[] = [];
	for (const entry of entries) {
		const text = entryToText(entry);
		if (!text || !text.text.trim()) continue;
		if (query && !text.text.toLowerCase().includes(query.toLowerCase())) continue;
		collected.push({
			id: entry.id,
			at: entry.timestamp,
			kind: text.kind,
			text: text.text,
		});
	}
	const selected = collected.slice(-limit).reverse();
	const header = `Raw session history: ${collected.length} matching entr${collected.length === 1 ? "y" : "ies"} of ${entries.length} total (compacted entries included).`;
	if (selected.length === 0) return `${header}\nNo matches for ${query ? `"${query}"` : "the request"}.`;
	const lines = [header];
	for (const entry of selected) {
		lines.push("", `[${entry.id}] ${entry.at} ${entry.kind}`, snippet(entry.text, query ?? ""));
	}
	return truncateBytes(lines.join("\n"), 14 * 1024).text;
}
