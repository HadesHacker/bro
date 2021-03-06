# @TEST-EXEC: bro -b %INPUT
# @TEST-EXEC: btest-diff test.log

module Test;

export {
	redef enum Log::ID += { LOG };

	type Log: record {
		ss: set[string];
	} &log;
}

event bro_init()
{
	Log::create_stream(Test::LOG, [$columns=Log]);


	Log::write(Test::LOG, [$ss=set("AA", ",", ",,", "CC")]);
}

