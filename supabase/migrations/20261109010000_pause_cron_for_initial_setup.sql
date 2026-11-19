-- 비아하우스 최초 설치 보호: 예시 데이터 정리 전 자동 작업이 Notion 데이터를 바꾸지 않도록 중지.
-- 예시 데이터 정리·연결 검증 후 운영 관리자가 이 작업을 재개한다.
do $$
declare
  job record;
  expected_names text[] := array[
    'process-sync-queue-every-minute', 'status-watchdog-every-15-minutes',
    'sync-failure-audit-every-30-minutes', 'backfill-assignment-deadlines-every-10min',
    'kiosk-prepare-daily', 'class-room-copy-first-fill', 'class-room-copy-incremental',
    'class-room-copy-reconcile-sessions', 'class-room-copy-reconcile-attendance',
    'class-room-copy-reconcile-records', 'class-room-copy-reconcile-activities',
    'library-copy-reconcile'
  ];
  optional_names text[] := array[
    'app-copy-first-fill', 'app-copy-incremental', 'app-copy-reconcile'
  ];
  matched integer;
begin
  select count(*) into matched from cron.job where jobname = any(expected_names);
  if matched <> cardinality(expected_names) then
    raise exception '설치 예약 작업 수 불일치: expected %, found %', cardinality(expected_names), matched;
  end if;
  -- 새 작업은 이 마이그레이션보다 나중에 생성되므로, 존재할 때만 함께 중지한다.
  -- 실제 신규 생성·재등록 시의 즉시 중지는 해당 마이그레이션에서 보장한다.
  for job in select jobid from cron.job where jobname = any(expected_names || optional_names) and active loop
    perform cron.alter_job(job_id := job.jobid, active := false);
  end loop;
end $$;
