create database JobPostDB


Go 

USE JobPostDB
--DROP DATABASE JobPostDB

CREATE TABLE Users(
userId int IDENTITY PRIMARY KEY,
userName varchar(10),
email varchar(10) UNIQUE,
password varchar(10),
type varchar(10),
CHECK (type in ('student', 'college', 'employer'))
);

CREATE TABLE Student (
sid int PRIMARY KEY REFERENCES Users(userId) on DELETE CASCADE on UPDATE CASCADE,
studentName varchar(10),
gpa decimal(3,2),
graduationDate date,
degree varchar(10),
gender bit,  --   0-->male   1-->female
jid int REFERENCES Job(jid) on DELETE CASCADE on UPDATE CASCADE,--new  assuming that the student is hired in only one job
eid int REFERENCES Employer(eid) on DELETE CASCADE on UPDATE CASCADE,--new
Check (gpa between 0.00 and 4.00)
);

CREATE TABLE College(
cid int PRIMARY KEY REFERENCES Users(userId) on DELETE CASCADE on UPDATE CASCADE,
collegeName varchar(10),
collegeAddress varchar(10),
collegeCity varchar(10),
collegeState varchar(10),
collegeZip char(5) ,
mission varchar(10),
website varchar(10),
phoneNumber varchar(11)
);

--multivalued attributes [college degrees,required certifications for a job,required skills for a job]
CREATE TABLE CollegeDegrees(
id int REFERENCES College(cid) on DELETE CASCADE on UPDATE CASCADE,
degree varchar(10),
PRIMARY KEY(id, degree)
);


CREATE TABLE Employer(
eid int PRIMARY KEY REFERENCES Users(userId) on DELETE CASCADE on UPDATE CASCADE,
companyName varchar(10),
companyContact varchar(10),
companyAddress varchar(10),
companyCity varchar(10),
companyState varchar(10),
companyZip char(5) ,
phoneNumber varchar(11)
);


CREATE TABLE Job(
jid int PRIMARY KEY IDENTITY,
jobTitle varchar(10),
jobType varchar(10),
salary int,
requiredExperience varchar(10),
jobDescription varchar(10),
startDate date,
employerId int, --new
localArea varchar(10),--new
region varchar(10),--new
state varchar(10),--new
Foreign KEY (employerId) REFERENCES Employer(eid) on DELETE No Action on UPDATE No Action,--new
CHECK (jobType in ('part-time', 'full-time', 'internship'))--check on type
);


CREATE TABLE JobRequiredCertifications(
id int REFERENCES Job(jid) on DELETE CASCADE on UPDATE CASCADE,
requiredCertification varchar(10),
PRIMARY KEY(id, requiredCertification)
);

CREATE TABLE JobRequiredSkills(
id int REFERENCES Job(jid) on DELETE CASCADE on UPDATE CASCADE,
requiredSkill varchar(10),
PRIMARY KEY(id, requiredSkill)
);

--The relation between the student entity and the job entity when a student is applying for job(s)
CREATE TABLE StudentAppliesForJob(
sid int REFERENCES Student(sid) on DELETE No Action on UPDATE No Action,
jid int REFERENCES Job(jid) on DELETE No Action on UPDATE No Action,
PRIMARY KEY(sid, jid)
);

--------------------------------------------------Procedures----------------------------------------------------------
go
----------------------------------------
Create proc userLogin
@id int,
@password varchar(20),
@success bit output,
@type varchar(10) output
as
begin
if exists(
select userId,password
from users
where userId=@id and password=@password)
begin
set @success =1        --there exists a user with these credentials (login succeeded)
-- check user type -->Employer , -->College ,-->Student
if exists(select eid from Employer where eid=@id)
set @type='Employer'  --the logged in user is of type Employer
if exists(select cid from College where cid=@id)
set @type='College'	  --the logged in user is of type College
if exists(select sid from Student where sid=@id)
set @type='Student'   --the logged in user is of type Student
end
else 
begin
set @success=0     -- user is not found and login failed
set @type='Not A User'
end
end

----------------------------------------------------------------
go
create proc studentRegister
@student_name varchar(10),
@user_name varchar(10),
@password varchar(10),
@email varchar(10),
@gender bit,
@gpa decimal(3,2),
@grad_date date,
@degree varchar(10)
as
begin

insert into Users values(@user_name,@email,@password,'Student')
declare @id int
SELECT @id=SCOPE_IDENTITY()
insert into Student(sid,studentName,gpa,graduationDate,degree,gender) values(@id,@student_name,@gpa,@grad_date,@degree,@gender)


end
--------------------------------------------------------------------------

go
create proc collegeRegister   ---to be continued
@college_name varchar(10),
@user_name varchar(10),
@password varchar(10),
@email varchar(10),
@address varchar(10),
@city varchar(10),
@state varchar(10),
@zip char(5) ,
@mission varchar(10),
@website varchar(10),
@phone_number varchar(11)
as
begin

insert into Users values(@user_name,@email,@password,'College')
declare @id int
SELECT @id=SCOPE_IDENTITY()
insert into College values(@id,@college_name,@address,@city,@state,@zip,@mission,@website,@phone_number)


end
------------------------------------------------------------------------------
go
create proc employerRegister     ---to be continued 
@company_name varchar(10),
@user_name varchar(10),
@password varchar(10),
@email varchar(10),
@contact varchar(10),
@address varchar(10),       
@city varchar(10),
@state varchar(10),
@zip char(5) ,
@phone_num varchar(11)
as
begin

insert into Users values(@user_name,@email,@password,'Employer')
declare @id int
SELECT @id=SCOPE_IDENTITY()
insert into Employer values(@id,@company_name,@contact,@address,@city,@state,@zip,@phone_num)

end
--------------------------------------------------------
go
create proc addCollegeDegrees    -- as college degrees is a multivalued attribute so, the procedure has to be called each time a degree has to be added for a specific college
@id int,
@degree varchar(10)
as
begin
if @id is not null and @degree is not null
insert into CollegeDegrees values(@id,@degree)
end
----------------------------------------------------------
go 
create proc jobPosting  -- a specific employer is posting a job
@eid int,
@jobTitle varchar(10),
@jobType varchar(10),--check on type
@salary int,
@requiredExperience varchar(10),
@jobDescription varchar(10),
@startDate date,
@localArea varchar(10),
@region varchar(10),
@state varchar(10)
as
begin
insert into Job(jobTitle,jobType,salary,requiredExperience,jobDescription,startDate,employerId,localArea,region,state) values(@jobTitle,@jobType,@salary,@requiredExperience,@jobDescription,@startDate,@eid,@localArea,@region,@state)
end
-------------------------------------------------------------
go
create proc studentApplyingForAJob
@sid int,
@jid int
as
begin
insert into StudentAppliesForJob values(@sid,@jid)
end
-------------------------------------------------------------
go
create proc employerHiresAStudent
@eid int,
@sid int,
@jid int
as
begin
update Student
set  jid=@jid, eid=@eid
where sid=@sid
end
---------------------------------------------------------------
go
create proc addRequiredCertificationForAJob   -- as required certification is a multivalued attribute so, the procedure has to be called each time a certification is required for a specific job
@jid int,
@certification varchar(10)
as
begin
if @jid is not null and @certification is not null
insert into JobRequiredCertifications values(@jid,@certification)
end
----------------------------------------------------------------
go
create proc addRequiredSkillsForAJob   -- as required skills is a multivalued attribute so, the procedure has to be called each time another skill is required for a specific job
@jid int,
@skill varchar(10)
as
begin
if @jid is not null and @skill is not null
insert into JobRequiredSkills values(@jid,@skill)
end
-----------------------------------------------------------------
go
create proc sortJobsByRegion
as
begin
select *
from Job
order by region
end
-----------------------------------------------------------------
go
create proc sortJobsByState
as
begin
select *
from Job
order by state
end
-----------------------------------------------------------------
go
create proc sortJobsBylocalArea
as
begin
select *
from Job
order by localArea
end