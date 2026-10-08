-- ==============================================================================
-- BinaPro - Supabase Database & Storage Setup Script
-- سكربت إعداد قاعدة بيانات ومساحة تخزين Supabase لمشروع كتالوج المقاولات
-- ==============================================================================

-- 1. جدول المشاريع الرئيسية (projects)
create table if not exists public.projects (
    id uuid default gen_random_uuid() primary key,
    building_name text not null,
    district text not null,
    work_type text not null,
    main_image_url text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. جدول الصور الفرعية للمشروع (project_images)
create table if not exists public.project_images (
    id uuid default gen_random_uuid() primary key,
    project_id uuid references public.projects(id) on delete cascade not null,
    image_url text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- فهرس لتسريع استعلامات صور المشروع
create index if not exists idx_project_images_project_id on public.project_images(project_id);

-- 3. تفعيل الحماية RLS (Row Level Security) وتعيين سياسات الوصول
alter table public.projects enable row level security;
alter table public.project_images enable row level security;

-- السماح للجميع (العام) بقراءة المشاريع والصور
drop policy if exists "Public Read Projects" on public.projects;
create policy "Public Read Projects" on public.projects 
    for select using (true);

drop policy if exists "Public Read Project Images" on public.project_images;
create policy "Public Read Project Images" on public.project_images 
    for select using (true);

-- السماح للمدير (وكذلك المفتاح العام للمشروع) بإضافة وتعديل وحذف المشاريع
drop policy if exists "Allow Full Access Projects" on public.projects;
create policy "Allow Full Access Projects" on public.projects 
    for all using (true) with check (true);

drop policy if exists "Allow Full Access Project Images" on public.project_images;
create policy "Allow Full Access Project Images" on public.project_images 
    for all using (true) with check (true);

-- 4. إعداد حاوية التخزين للصور (Storage Bucket: project-images)
insert into storage.buckets (id, name, public) 
values ('project-images', 'project-images', true)
on conflict (id) do update set public = true;

-- سياسات التخزين
drop policy if exists "Public Access Storage" on storage.objects;
create policy "Public Access Storage" on storage.objects 
    for select using (bucket_id = 'project-images');

drop policy if exists "Allow Uploads Storage" on storage.objects;
create policy "Allow Uploads Storage" on storage.objects 
    for insert with check (bucket_id = 'project-images');

drop policy if exists "Allow Update Storage" on storage.objects;
create policy "Allow Update Storage" on storage.objects 
    for update using (bucket_id = 'project-images');

drop policy if exists "Allow Delete Storage" on storage.objects;
create policy "Allow Delete Storage" on storage.objects 
    for delete using (bucket_id = 'project-images');

-- 5. تأكيد بريد حساب المدير تلقائياً في حال تسجيله
update auth.users 
set email_confirmed_at = timezone('utc'::text, now()) 
where email = 'admin@ovrax.com';
