-- 비아 초기 설치 보호: app-copy 예약 작업 세 개를 확인하고 비활성화한다.
-- 원본 예약 생성 후 별도 마이그레이션으로 중지한다. 그 사이 실행 가능성은 남는다.
-- 세 작업을 중지하고 같은 실행에서 활성 0건을 검사한다. 배포 직후에도 별도로 재확인한다.
-- 활성화는 이관 검증 뒤 대표가 별도로 승인한다.
do $$
declare
  job record;
  expected_names text[] := array['app-copy-first-fill', 'app-copy-incremental', 'app-copy-reconcile'];
  matched integer;
begin
  select count(*) into matched from cron.job where jobname = any(expected_names);
  if matched <> cardinality(expected_names) then
    raise exception 'app-copy 예약 작업 수 불일치: expected %, found %', cardinality(expected_names), matched;
  end if;
  for job in select jobid from cron.job where jobname = any(expected_names) and active loop
    perform cron.alter_job(job_id := job.jobid, active := false);
  end loop;
  if exists (select 1 from cron.job where jobname = any(expected_names) and active) then
    raise exception 'app-copy 예약 작업이 여전히 활성화되어 있습니다';
  end if;
  raise notice '비아 app-copy 예약 작업 %개 확인, 활성 작업 0개', matched;
end $$;
