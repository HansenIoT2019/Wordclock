-- As we are located in central europe, we have GMT+1
local TIMEZONE_OFFSET_WINTER = 1

--Summer winter time convertion
--See: https://arduinodiy.wordpress.com/2015/10/13/the-arduino-and-daylight-saving-time/
--
--As October has 31 days, we know that the last Sunday will always fall from the 25th to the 31st
--So our check at the end of daylight saving will be as follows:
--if (dow == 7 && mo == 10 && d >= 25 && d <=31 && h == 3 && DST==1)
--{
--setclockto 2 am;
--DST=0;
--}
--
--To start summertime/daylightsaving time on the last Sunday in March is mutatis mutandis the same:
--if (dow == 7 && mo == 3 && d >= 25 && d <=31 && h ==2 && DST==0)
--{
--setclockto 3 am;
--DST=1;
--}
function getLocalTime(year, month, day, hour, minutes, second,dow)
  -- Always adapte the timezoneoffset:
  hour = hour + (TIMEZONE_OFFSET_WINTER)

  -- we are in 100% in the summer time
  if (month > 3 and month < 10) then 
    hour = hour + 1
  -- March is not 100% Summer time, only starting at the last sunday
  elseif ((month == 3 and day >= 25 and day <= 31 and hour > 2 and dow == 7) or
          -- Only handle days after the last sunday in this month
          ((month == 3 and day >= 25 and day <= 31 and dow < 7 and ((7-dow + day) > 31))) ) then
   -- set summer time
   hour = hour + 1
  -- October is not 100% Summer time, ending with the last sunday
  elseif ((month == 10 and day >= 25 and day <= 31 and hour <= 2 and dow == 7) or
          (month == 10 and day >= 25 and day <= 31 and dow < 7 and ((7-dow + day) <= 31)) or 
           -- Handle all days up to the 25. of october
           (month == 10 and day < 25 )
           )then
   -- set summer time
   hour = hour + 1
  end
  
  return year, month, day, hour, minutes, second
end

-- Convert a given month in english abr. to number from 1 to 12.
-- On unknown arguments, zero is returned.
function convertMonth(str)
 if (str=="Jan") then
  return 1
 elseif (str == "Feb") then
  return 2
 elseif (str == "Mar") then
  return 3
 elseif (str == "Apr") then
  return 4
 elseif (str == "May") then
  return 5
 elseif (str == "Jun") then
  return 6
 elseif (str == "Jul") then
  return 7
 elseif (str == "Aug") then
  return 8
 elseif (str == "Sep") then
  return 9
 elseif (str == "Oct") then
  return 10
 elseif (str == "Nov") then
  return 11
 elseif (str == "Dec") then
  return 12
 else
  return 0
 end
end

----------------------------------------------------------
-- Here comes some code to extract the year, month, day, hour, minute, second and day of week of a unix timestamp

-- Source:
-- http://www.jbox.dk/sanos/source/lib/time.c.html

YEAR0=1900

EPOCH_YR=1970
--SECS_DAY=(24L * 60L * 60L)
SECS_DAY=86400

ytab = {}
ytab[0] = {}
ytab[1] = {}
ytab[0][0] = 31
ytab[0][1] = 28
ytab[0][2] = 31
ytab[0][3] = 30
ytab[0][4] = 31
ytab[0][5] = 30
ytab[0][6] = 31
ytab[0][7] = 31
ytab[0][8] = 30
ytab[0][9] = 31
ytab[0][10] = 30
ytab[0][11] = 31
ytab[1][0] =  31
ytab[1][1] = 29
ytab[1][2] = 31
ytab[1][3] = 30
ytab[1][4] = 31
ytab[1][5] = 30
ytab[1][6] = 31
ytab[1][7] = 31
ytab[1][8] = 30
ytab[1][9] = 31
ytab[1][10] = 30
ytab[1][11] = 31


local leapyear = function(year)
    return  ( not ((year) % 4 ~= 0) and (((year) % 100 ~= 0) or not ((year) % 400 ~= 0)))
end

local yearsize = function(year)
 if leapyear(year) then
  return 366
 else
  return 365
 end
end

gettime = function(unixtimestmp)
  local year = EPOCH_YR
  local dayclock = math.floor(unixtimestmp % SECS_DAY)
  dayno = math.floor(unixtimestmp / SECS_DAY)

  local sec = math.floor(dayclock % 60)
  local min = math.floor( (dayclock % 3600) / 60)
  local hour = math.floor(dayclock / 3600)
  local wday = math.floor( (dayno + 4) % 7) -- Day 0 was a thursday

  while (dayno >= yearsize(year))
  do
    dayno = dayno - yearsize(year);
    year=year + 1
  end
  --Day in whole year: local yday = dayno (Not needed)
  mon = 0
  while (dayno >= ytab[leapyear(year) and 1 or 0][mon])
  do
      dayno = dayno - ytab[leapyear(year) and 1 or 0][mon];
      mon = mon + 1
   end
   mday = dayno + 1

  return year, (mon+1), mday, hour, min, sec, wday
end


