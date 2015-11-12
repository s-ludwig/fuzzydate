/** Contains functions for converting an exact date to a fuzzy human readable form.
*/
module fuzzydate;

import std.datetime : Clock, SysTime, UTC;

/** Converts a certain date/time to a fuzzy string
*/
string toFuzzyDate(SysTime time)
{
	return toFuzzyDate(time, Clock.currTime(UTC()));
}

/// ditto
string toFuzzyDate(SysTime time, SysTime now)
{
	import std.array : appender;
	auto app = appender!string();
	app.toFuzzyDate(time, now);
	return app.data;
}

/// ditto
void toFuzzyDate(R)(ref R dst, SysTime time)
{
	toFuzzyDate(dst, time, Clock.currTime(UTC()));
}

/// ditto
void toFuzzyDate(R)(ref R dst, SysTime time, SysTime now)
{
	import core.time : dur;
	import std.format : formattedWrite;

	auto tm = now - time;
	if (tm < dur!"seconds"(0)) dst.put("still going to happen");
	else if (tm < dur!"seconds"(1)) dst.put("just now");
	else if (tm < dur!"minutes"(1)) dst.put("less than a minute ago");
	else if (tm < dur!"minutes"(2)) dst.put("a minute ago");
	else if (tm < dur!"hours"(1)) dst.formattedWrite("%s minutes ago", tm.total!"minutes"());
	else if (tm < dur!"hours"(2)) dst.put("an hour ago");
	else if (tm < dur!"days"(1)) dst.formattedWrite("%s hours ago", tm.total!"hours"());
	else if (tm < dur!"days"(2)) dst.put("a day ago");
	else if (tm < dur!"weeks"(5)) dst.formattedWrite("%s days ago", tm.total!"days"());
	else if (tm < dur!"weeks"(52)) {
		auto m1 = time.month;
		auto m2 = now.month;
		auto months = (now.year - time.year) * 12 + m2 - m1;
		if (months == 1) dst.put("a month ago");
		else dst.formattedWrite("%s months ago", months);
	} else if (now.year - time.year <= 1) dst.put("a year ago");
	else dst.formattedWrite("%s years ago", now.year - time.year);
}
