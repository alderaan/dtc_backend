-- First, create a status enum for the human-in-the-loop process.
CREATE TYPE public.dtc_profile_status AS ENUM (
  'active',
  'pending_review',
  'flagged_for_removal',
  'removed'
);

-- Table to store the core, unique Instagram profile identity.
CREATE TABLE public.dtc_profiles (
    id bigserial PRIMARY KEY,
    username text NOT NULL UNIQUE,
    country text, -- Can be null
    status public.dtc_profile_status NOT NULL DEFAULT 'active',
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Table to store unique search keywords and their metadata.
CREATE TABLE public.dtc_keywords (
    id bigserial PRIMARY KEY,
    search_term text NOT NULL,
    country text NOT NULL, -- No default value
    category text,
    keyword_en text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    -- Ensures that each combination of search term, country, category, and translation is unique.
    CONSTRAINT uq_keyword_details UNIQUE (search_term, category, keyword_en, country)
);

-- Junction table to link profiles and the keywords they were found with.
CREATE TABLE public.dtc_profile_keywords (
    profile_id bigint NOT NULL REFERENCES public.dtc_profiles(id) ON DELETE CASCADE,
    keyword_id bigint NOT NULL REFERENCES public.dtc_keywords(id) ON DELETE RESTRICT,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (profile_id, keyword_id)
);

-- Table to store historical/versioned data scraped from profiles.
CREATE TABLE public.dtc_profile_details (
    id bigserial PRIMARY KEY,
    profile_id bigint NOT NULL REFERENCES public.dtc_profiles(id) ON DELETE CASCADE,
    full_name text,
    biography text,
    external_url text,
    followers_count integer,
    following_count integer,
    posts_count integer,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.dtc_raw_google_search_results (
    id bigserial PRIMARY KEY,
    keyword_id bigint,
    country_code text,
    data jsonb NOT NULL,
    loaded_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.dtc_raw_instagram_profiles (
    id bigserial PRIMARY KEY,
    keyword_id bigint,
    country_code text,
    data jsonb NOT NULL,
    loaded_at timestamp with time zone DEFAULT now()
);

-- Create indexes on frequently queried columns for better performance.
CREATE INDEX idx_dtc_profiles_username ON public.dtc_profiles(username);
CREATE INDEX idx_dtc_profiles_country ON public.dtc_profiles(country);
CREATE INDEX idx_dtc_profile_details_profile_id ON public.dtc_profile_details(profile_id);
CREATE INDEX idx_dtc_profile_details_created_at ON public.dtc_profile_details(created_at DESC);
CREATE INDEX idx_dtc_raw_google_search_results_keyword_id
ON public.dtc_raw_google_search_results(keyword_id);
CREATE INDEX idx_dtc_raw_instagram_profiles_keyword_id
ON public.dtc_raw_instagram_profiles(keyword_id);

-- Function and Trigger to automatically update the 'updated_at' timestamp on the profiles table.
CREATE OR REPLACE FUNCTION public.handle_dtc_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_dtc_profiles_update
  BEFORE UPDATE ON public.dtc_profiles
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_dtc_updated_at();
  


-- UPDATED VIEW to include the new country column from dtc_profiles
CREATE OR REPLACE VIEW public.dtc_profiles_with_latest_details AS
SELECT DISTINCT ON (p.id)
    p.id,
    p.username,
    p.country,
    p.status,
    p.notes,
    p.updated_at,
    pd.full_name,
    pd.biography,
    pd.followers_count,
    pd.posts_count,
    pd.external_url,
    pd.created_at AS last_scraped_at,
    'https://www.instagram.com/'::text || p.username AS profile_url,
    k.search_term,
    k.keyword_en AS search_term_en,
    k.category,
    k.country as keyword_country
FROM
    public.dtc_profiles p
LEFT JOIN
    public.dtc_profile_details pd ON p.id = pd.profile_id
LEFT JOIN (
    SELECT DISTINCT ON (pk.profile_id)
        pk.profile_id,
        pk.keyword_id
    FROM
        public.dtc_profile_keywords pk
    ORDER BY
        pk.profile_id, pk.created_at DESC
) AS latest_pk ON p.id = latest_pk.profile_id
LEFT JOIN
    public.dtc_keywords k ON latest_pk.keyword_id = k.id
ORDER BY
    p.id, pd.created_at DESC;

