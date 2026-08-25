export const learnerTypes=[["preschool","Tiền tiểu học"],["primary","Tiểu học"],["middle_school","THCS"],["high_school","THPT"],["university","Đại học"],["postgraduate","Sau đại học"],["working","Đi làm"],["senior","Người lớn tuổi"]] as const;
export type LearnerType=(typeof learnerTypes)[number][0];
export type AppRole="learner"|"admin";
export type VocabularyWord={id:string;term:string;ipa:string|null;meaning_vi:string;example_en:string|null;example_vi:string|null;audio_url:string|null;part_of_speech:string|null};
export type LessonWord={position:number;word:VocabularyWord};
