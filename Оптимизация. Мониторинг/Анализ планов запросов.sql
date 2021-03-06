USE master
 
declare
@QueryLike varchar(20) = '' --Like-фильтр для поиска отдельных запросов
 
if OBJECT_ID('tempdb..#plans_summary') is not null drop table #plans_summary; 
 
with  
  /*Статистика времени выполнения */
  execution_stats(plan_handle, subqueries, creation_time, last_execution_time, total_worker_time, average_worker_time, total_elapsed_time, average_elapsed_time, query_plan_hash, query_hash) as
  (
  select 
    qs.plan_handle, 
    COUNT_BIG(*) as subqueries,
    MIN(qs.creation_time) as creation_time,
    MAX(qs.last_execution_time) as last_execution_time,
    CAST(SUM(qs.total_worker_time)/1000.0 as decimal(20,2)) as total_worker_time, --процессорное время
    CAST(SUM(qs.total_worker_time / qs.execution_count)/1000.0 as decimal(20,2)) as average_worker_time, 
    CAST(SUM(qs.total_elapsed_time)/1000.0 as decimal(20,2)) as total_elapsed_time, --фактическое время
    CAST(SUM(qs.total_elapsed_time / qs.execution_count)/1000.0 as decimal(20,2)) as average_elapsed_time,
    case when COUNT_BIG(*) = 1 then MIN(qs.query_plan_hash) else null end as query_plan_hash,
    case when COUNT_BIG(*) = 1 then MIN(qs.query_hash) else null end as query_hash
  from 
    sys.dm_exec_query_stats qs
  group by qs.plan_handle
  ),
  plans_summary([db_name], objtype, usecounts, compile_time, compile_cpu, total_worker_time, average_worker_time, total_elapsed_time, average_elapsed_time, query_text, size_in_kb, plan_subqueries, stats_subqueries, creation_time, last_execution_time, plan_handle, parameterized_plan_handle, query_plan_hash, query_hash, query_plan) as
  (
  select
    DB_NAME(CONVERT(int, epa.value)) as [db_name],
    cp.objtype,
    cp.usecounts,
    CAST(0.00 as numeric(25,2))as compile_time,
    CAST(0.00 as numeric(25,2)) as compile_cpu,
    es.total_worker_time, 
    es.average_worker_time, 
    es.total_elapsed_time, 
    es.average_elapsed_time, 
    st.text as query_text,
    cp.size_in_bytes / 1024 as size_in_kb,
    CAST(0 as int) as plan_subqueries,
    es.subqueries as stats_subqueries,
    es.creation_time, 
    es.last_execution_time, 
    cp.plan_handle,
    case 
      when es.subqueries is null
      then qp.query_plan.value('declare namespace D="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (//D:StmtSimple)[1]/@ParameterizedPlanHandle', 'NVARCHAR(128)')
      else null
    end,
    es.query_plan_hash, 
    es.query_hash,
    qp.query_plan
  from
    sys.dm_exec_cached_plans cp
    left join execution_stats es on (cp.plan_handle = es.plan_handle)
    cross apply sys.dm_exec_query_plan(cp.plan_handle) qp
    cross apply sys.dm_exec_plan_attributes(cp.plan_handle) epa
    cross apply sys.dm_exec_sql_text(cp.plan_handle) st
  where 
    (cp.objtype in ('Adhoc', 'Prepared')) and -- Отфильтровать кэш по планам запросов
    (epa.attribute = 'dbid') and 
    (DB_NAME(CONVERT(int, epa.value)) not in ('msdb', 'master', 'model')) and -- Исключить из статистики запросы из системных БД
    ((@QueryLike = '') or (st.text like @QueryLike)) -- Применить like-фильтр, если он задан
  )
 
  select * into #plans_summary from plans_summary
 
  /*Добавить статистику по компиляции планов*/
  update #plans_summary set
    plan_subqueries = t.subqueries,
    compile_cpu = t.compile_cpu,
    compile_time = t.compile_time
  from 
    #plans_summary ps
    join
    (
    select 
      SUM(query_plan_nodes.query_plan_node.value('(@CompileTime)[1]', 'int')) as compile_time,
      SUM(query_plan_nodes.query_plan_node.value('(@CompileCPU)[1]', 'int')) as compile_cpu, 
      ps.plan_handle,
      COUNT_BIG(*) as subqueries
    from 
      #plans_summary ps
      cross apply ps.query_plan.nodes('declare namespace D="http://schemas.microsoft.com/sqlserver/2004/07/showplan"; //D:QueryPlan') as query_plan_nodes(query_plan_node)
    group by ps.plan_handle
    ) t on (ps.plan_handle = t.plan_handle)
  option (recompile)


-- Одноразовые планы
  select 
  SUM(case when parameterized_plan_handle is null then 1 end) as 'Count Normal',
  SUM(case when parameterized_plan_handle is not null then 1 end) as 'Count Shell',
  CAST(SUM(compile_time) / 1000 as numeric(25,2)) as 'Compile Time (sec)',
  CAST(SUM(compile_cpu) / 1000 as numeric(25,2)) as 'Compile CPU Time (sec)',
  CAST(SUM(total_elapsed_time) / 1000 as numeric(25,2)) as 'Elapsed Time (sec)',
  CAST(SUM(total_worker_time) / 1000 as numeric(25,2)) as 'Worker Time (sec)',
  CAST(SUM(case when parameterized_plan_handle is null then size_in_kb else 0 end) /1024 as numeric(15,2)) as 'Size Normal (MB)',
  CAST(SUM(case when parameterized_plan_handle is not null then size_in_kb else 0 end) /1024 as numeric(15,2)) as 'Size Shell (MB)',
  CAST(DATEDIFF(MI, MIN(creation_time), GETDATE()) / 60.0 as numeric(25,2)) as 'TTL (hours)'
from #plans_summary
where (usecounts = 1)
and (objtype = 'Adhoc') -- можно убрать если хотим проанализировать все планы
option (recompile)

-- Многоразовые планы
select 
  SUM(case when parameterized_plan_handle is null then 1 end) as 'Count Normal',
  SUM(case when parameterized_plan_handle is not null then 1 end) as 'Count Shell',
  CAST(SUM(compile_time) / 1000 as numeric(15,2)) as 'Compile Time (sec)',
  CAST(SUM(compile_cpu) / 1000 as numeric(15,2)) as 'Compile CPU Time (sec)',
  CAST(SUM(total_elapsed_time) / 1000 as numeric(15,2)) as 'Elapsed Time (sec)',
  CAST(SUM(total_worker_time) / 1000 as numeric(15,2)) as 'Worker Time (sec)',
  CAST(SUM(case when parameterized_plan_handle is null then size_in_kb else 0 end) /1024 as numeric(15,2)) as 'Size Normal (MB)',
  CAST(SUM(case when parameterized_plan_handle is not null then size_in_kb else 0 end) /1024 as numeric(15,2)) as 'Size Shell (MB)'
from #plans_summary
where (usecounts > 1)
and (objtype = 'Adhoc') -- можно убрать если хотим проанализировать все планы
option (recompile)

-- Количество планов по запросам
select
  query_hash as 'Query Hash',
  COUNT(*) as 'Count',
  CAST(SUM(compile_time) / 1000 as numeric(15,2)) as 'Compile Time (sec)',
  CAST(SUM(compile_cpu) / 1000 as numeric(15,2)) as 'Compile CPU Time (sec)',
  CAST(SUM(total_elapsed_time) / 1000 as numeric(15,2)) as 'Elapsed Time (sec)',
  CAST(SUM(total_worker_time) / 1000 as numeric(15,2)) as 'Worker Time (sec)',    
  CAST(SUM(size_in_kb) /1024 as numeric(15,2)) as 'Size (MB)'
from #plans_summary
where (query_hash is not null) and (objtype = 'Adhoc') and (parameterized_plan_handle is null)
group by GROUPING sets (query_hash, ())
having (COUNT(*) > 1)
order by 2 desc
option(recompile)

-- Компиляция дольше чем выполнение
select
  query_hash as 'Query Hash',
  COUNT(*) as 'Count',
  SUM(compile_time) as 'Compile Time (msec)',
  SUM(total_elapsed_time) as 'Elapsed Time (msec)',
  SUM(size_in_kb) as 'Size (KB)'
from #plans_summary
where (query_hash is not null) and (objtype = 'Adhoc') and (parameterized_plan_handle is null)
group by query_hash
having (SUM(compile_time) - SUM(total_elapsed_time)) > 0
order by SUM(compile_time) - SUM(total_elapsed_time) desc
option(recompile)

-- Схожие параметризированные запросы
select
  query_hash as 'Query Hash',
  COUNT(*) as 'Count',
  CAST(SUM(compile_time) / 1000 as numeric(15,2)) as 'Compile Time (sec)',
  CAST(SUM(compile_cpu) / 1000 as numeric(15,2)) as 'Compile CPU Time (sec)',
  CAST(SUM(total_elapsed_time) / 1000 as numeric(15,2)) as 'Elapsed Time (sec)',
  CAST(SUM(total_worker_time) / 1000 as numeric(15,2)) as 'Worker Time (sec)',   
  CAST(SUM(size_in_kb) /1024 as numeric(15,2)) as 'Size (MB)'
from #plans_summary
where (query_hash is not null) and (objtype = 'Prepared')
group by GROUPING sets (query_hash, ())
having (COUNT(*) > 1)
order by 2 desc
option(recompile)

-- Информация о планах по одному запросу
select 
  usecounts,
  compile_time,
  total_worker_time,
  total_elapsed_time, 
  size_in_kb,
  query_plan
from #plans_summary 
where 
  (query_hash = 0x6D2B728403444433) 
  --(total_worker_time > total_elapsed_time) 
option(recompile)