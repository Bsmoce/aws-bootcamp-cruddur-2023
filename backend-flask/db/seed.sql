INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Bassam', 'Bassamasar@duck.com', 'BSM101' ,'MOCK'),
  ('Andrew Brown', '9i3yd1jk@duck.com', 'andrewbrown' ,'MOCK');
  

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'BSM101' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )