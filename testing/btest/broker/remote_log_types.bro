# @TEST-SERIALIZE: comm

# @TEST-EXEC: btest-bg-run recv "bro -b ../recv.bro >recv.out"
# @TEST-EXEC: btest-bg-run send "bro -b ../send.bro >send.out"

# @TEST-EXEC: btest-bg-wait 20
# @TEST-EXEC: btest-diff recv/recv.out
# @TEST-EXEC: btest-diff recv/test.log
# @TEST-EXEC: btest-diff send/send.out
# @TEST-EXEC: btest-diff send/test.log
# @TEST-EXEC: cat send/test.log | grep -v '#close' >send/test.log.filtered
# @TEST-EXEC: cat recv/test.log | grep -v '#close' >recv/test.log.filtered
# @TEST-EXEC: diff -u send/test.log.filtered recv/test.log.filtered

@TEST-START-FILE common.bro

redef Broker::default_connect_retry=1secs;
redef Broker::default_listen_retry=1secs;
redef exit_only_after_terminate = T;

global quit_receiver: event();
global quit_sender: event();


module Test;

export {
        redef enum Log::ID += { LOG };

	type Info: record {
		b: bool;
		i: int;
		e: Log::ID;
		c: count;
		p: port;
		sn: subnet;
		a: addr;
		d: double;
		t: time;
		iv: interval;
		s: string;
		sc: set[count];
		ss: set[string];
		se: set[string];
		vc: vector of count;
		ve: vector of string;
		f: function(i: count) : string;
	} &log;

}

event bro_init() &priority=5
        {
        Log::create_stream(Test::LOG, [$columns=Test::Info]);
        }

@TEST-END-FILE

@TEST-START-FILE recv.bro

@load ./common.bro

event bro_init()
	{
	Broker::subscribe("bro/");
	Broker::listen("127.0.0.1");
	}

event quit_receiver()
	{
	terminate();
	}

@TEST-END-FILE

@TEST-START-FILE send.bro



@load ./common.bro

event bro_init()
	{
	Broker::peer("127.0.0.1");
	}

event quit_sender()
	{
	terminate();
	}

function foo(i : count) : string
	{
	if ( i > 0 )
		return "Foo";
	else
		return "Bar";
	}

event Broker::peer_added(endpoint: Broker::EndpointInfo, msg: string)
	{
	print "Broker::peer_added", endpoint$network$address;

	local empty_set: set[string];
	local empty_vector: vector of string;
	
	Log::write(Test::LOG, [
		$b=T,
		$i=-42,
		$e=Test::LOG,
		$c=21,
		$p=123/tcp,
		$sn=10.0.0.1/24,
		$a=1.2.3.4,
		$d=3.14,
		$t=network_time(),
		$iv=100secs,
		$s="hurz",
		$sc=set(1), # set(1,2,3,4),  # Output not stable for multi-element sets.
		$ss=set("AA"), # set("AA", "BB", "CC") # Output not stable for multi-element sets.
		$se=empty_set,
		$vc=vector(10, 20, 30),
		$ve=empty_vector,
		$f=foo
		]);

	local e = Broker::make_event(quit_receiver);
	Broker::publish("bro/", e);
	schedule 1sec { quit_sender() };
        }


@TEST-END-FILE
