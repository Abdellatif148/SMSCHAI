-- Enable Row Level Security (RLS) is standard practice for user data privacy

-- TABLE 1: devices
-- Tracks every phone a user connects.
create table public.devices (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_name text not null,
  device_id text not null, -- Unique hardware ID from the device
  last_sync timestamp with time zone default now(),
  created_at timestamp with time zone default now(),
  
  primary key (id),
  unique(user_id, device_id) -- Prevent duplicate entries for the same device per user
);

-- Enable RLS for devices
alter table public.devices enable row level security;

-- Policies for devices
create policy "Users can view their own devices"
  on public.devices for select
  using (auth.uid() = user_id);

create policy "Users can insert their own devices"
  on public.devices for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own devices"
  on public.devices for update
  using (auth.uid() = user_id);

create policy "Users can delete their own devices"
  on public.devices for delete
  using (auth.uid() = user_id);


-- TABLE 2: messages_backup
-- Stores synced SMS. Body is encrypted locally before upload.
create table public.messages_backup (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id uuid references public.devices(id) on delete set null, -- Optional link to source device
  sms_id text not null, -- Local SMS ID (or composite key with device_id)
  sender text not null,
  receiver text not null,
  body text not null, -- ENCRYPTED CONTENT
  timestamp bigint not null, -- Unix timestamp in milliseconds
  read boolean default false,
  type integer default 1, -- 1=Inbox, 2=Sent (Added this as it's useful)
  created_at timestamp with time zone default now(),
  
  primary key (id)
);

-- Enable RLS for messages_backup
alter table public.messages_backup enable row level security;

-- Policies for messages_backup
create policy "Users can view their own messages"
  on public.messages_backup for select
  using (auth.uid() = user_id);

create policy "Users can insert their own messages"
  on public.messages_backup for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own messages"
  on public.messages_backup for update
  using (auth.uid() = user_id);

create policy "Users can delete their own messages"
  on public.messages_backup for delete
  using (auth.uid() = user_id);

-- Create an index on user_id and timestamp for faster queries
create index messages_backup_user_id_idx on public.messages_backup(user_id);
create index messages_backup_timestamp_idx on public.messages_backup(timestamp);
