export type LearnerType =
  | "preschool" | "primary" | "middle_school" | "high_school"
  | "university" | "postgraduate" | "working" | "senior";

export type Profile = {
  id: string; display_name: string | null; learner_type: LearnerType;
  learning_start_date: string | null; timezone: string;
};

export type Word = {
  id: string; word: string; ipa: string | null; meaning_vi: string;
  example_en: string | null; example_vi: string | null; audio_url: string | null;
};

export function getAvailableDay(start: string | null, now = new Date()) {
  if (!start) return 0;
  const s = new Date(start + "T00:00:00");
  const n = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.max(0, Math.floor((n.getTime()-s.getTime())/86400000)+1);
}