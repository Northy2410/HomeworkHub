-- Core schema for HomeworkHub (PostgreSQL)
-- Users and schools
CREATE TABLE schools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('student','teacher','admin','parent')),
  password_hash TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Classes and enrollment
CREATE TABLE classes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  teacher_id UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role_in_class TEXT NOT NULL CHECK (role_in_class IN ('student','teacher','assistant')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (class_id, user_id)
);

-- Assignments and question templates
CREATE TABLE assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE question_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  author_id UUID REFERENCES users(id),
  title TEXT,
  language TEXT DEFAULT 'en',
  template_json JSONB NOT NULL, -- contains template, var spec, answer spec
  skill_tags TEXT[], -- array of skill tags
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE question_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
  template_id UUID REFERENCES question_templates(id),
  params JSONB NOT NULL,
  seed BIGINT NOT NULL,
  generated_html TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Submissions and attempts
CREATE TABLE submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_instance_id UUID REFERENCES question_instances(id) ON DELETE CASCADE,
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  answer JSONB,
  graded BOOL DEFAULT FALSE,
  score NUMERIC,
  feedback JSONB,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (question_instance_id, student_id)
);

CREATE TABLE attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID REFERENCES submissions(id) ON DELETE CASCADE,
  attempt_number INT NOT NULL,
  answer JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Skill mastery
CREATE TABLE skill_mastery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES users(id) ON DELETE CASCADE,
  skill_tag TEXT NOT NULL,
  mastery_score NUMERIC DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (student_id, skill_tag)
);