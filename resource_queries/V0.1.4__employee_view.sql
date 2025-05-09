USE DATABASE {{ database }};
USE SCHEMA {{ schema }};

create or replace view employees_hired as(
wwith employee_data as(
  select 
    department_name, 
    job_name, 
    count(case when quarter(employee_hired_date)  = 1 then 1 end)AS Q1,
    count(case when quarter(employee_hired_date)  = 2 then 1 end)AS Q2,
    count(case when quarter(employee_hired_date)  = 3 then 1 end)AS Q3,
    count(case when quarter(employee_hired_date)  = 4 then 1 end)AS Q4
    from employee
        inner join departments
            on employee.employee_dpt_id = departments.department_id
        inner join jobs 
            on employee.employee_job_id = jobs.job_id
    where year(employee_hired_date) = '2021' 
    group by department_name, job_name
) select * from employee_data
   
)