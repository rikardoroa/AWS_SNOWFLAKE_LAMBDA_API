USE DATABASE {{ database }};
USE SCHEMA {{ schema }};

create or replace view hiring_avg_2021 as (
with all_hired_employee_data as (
select 
    department_id,
    department_name,
    count(employee_job_id) total_employees
    from departments
       inner join employee
       on employee.employee_dpt_id = departments.department_id
    group by department_id,department_name
) select * from all_hired_employee_data
  where total_employees > (select avg(total_emp) from 
   (
        select 
            department_id,
            department_name,
            count(employee_dpt_id) as total_emp
            from departments
               inner join employee
               on employee.employee_dpt_id = departments.department_id
            where year(employee_hired_date) = '2021' 
            group by department_name,department_id
    ))
    order by total_employees desc
)
    