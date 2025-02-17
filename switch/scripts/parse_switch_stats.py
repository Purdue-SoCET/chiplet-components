import sys
import json
import numpy

usage = """
Usage:
    parse_switch_stats.py <file name>
"""

def main():
    if len(sys.argv) != 2:
        print("Incorrect number of arguments!")
        print(usage)
        exit(1)
    file_name = sys.argv[1]

    with open(file_name, "r") as f:
        s = f.read()
        switch_stats = json.loads(s)
        buffer_stats = switch_stats[0]
        outport_stats = switch_stats[1]

        for i, buffer in enumerate(buffer_stats):
            packets_sent = buffer["packets_sent"]
            if packets_sent == 0:
                continue
            latency = buffer["latency"]
            active_time = buffer["active_time"]
            flits_per_packet = buffer["flits_per_packet"]
            time_spent_in_pipe = [x - y for x, y in zip(latency, active_time)]
            cycles_per_flit  = [x / y for x, y in zip(latency, flits_per_packet)]
            transfer_rate  = [x * 4 / y for x, y in zip(flits_per_packet, latency)]
            crossbar_cycles_per_flit  = [x / (y * 4) for x, y in zip(active_time, flits_per_packet)]
            crossbar_transfer_rate = [1 / x for x in crossbar_cycles_per_flit]

            avg_latency = numpy.average(latency)
            latency_stdev = numpy.std(latency)
            avg_active_time = numpy.average(active_time)
            active_time_stdev = numpy.std(active_time)
            avg_flits_per_packet = numpy.average(flits_per_packet)
            avg_time_spent_in_pipe = numpy.average(time_spent_in_pipe)
            time_spent_in_pipe_stdev = numpy.std(time_spent_in_pipe)
            avg_cycles_per_flit = numpy.average(cycles_per_flit)
            cycles_per_flit_stdev = numpy.std(cycles_per_flit)
            avg_transfer_rate = numpy.average(transfer_rate)
            transfer_rate_stdev = numpy.std(transfer_rate)
            avg_crossbar_cycles_per_flit = numpy.average(crossbar_cycles_per_flit)
            crossbar_cycles_per_flit_stdev = numpy.std(crossbar_cycles_per_flit)
            avg_crossbar_transfer_rate = numpy.average(crossbar_cycles_per_flit)
            crossbar_cycles_transfer_rate = numpy.std(crossbar_cycles_per_flit)

            print(f"Statistics for buffer {i}")
            print(f"Average latency (cycles): {avg_latency:.2f} +- {latency_stdev:.2f}")
            print(f"Average active time (cycles): {avg_active_time:.2f} +- {active_time_stdev:.2f}")
            print(f"Average time spent in pipe (cycles): {avg_time_spent_in_pipe:.2f} +- {time_spent_in_pipe_stdev:.2f}")
            print(f"Average flits per packet (flits): {avg_flits_per_packet:.2f}")
            print(f"Average cycles per flit: {avg_cycles_per_flit:.2f} +- {cycles_per_flit_stdev:.2f}")
            print(f"Average transfer rate: {avg_transfer_rate:.2f} +- {transfer_rate_stdev:.2f}B/cycle")
            print(f"Average crossbar cycles per flit: {avg_crossbar_cycles_per_flit:.2f} +- {crossbar_cycles_per_flit_stdev:.2f}")
            print(f"Average crossbar transfer rate: {avg_crossbar_transfer_rate:.2f} +- {crossbar_cycles_per_flit_stdev:.2f}B/cycle")
            print("")

        for i, outport in enumerate(outport_stats):
            for j, vc in enumerate(outport):
                outport_active_len = vc["outport_total_len"]
                if len(outport_active_len) == 0:
                    continue
                outport_packet_len = vc["outport_packet_len"]
                outport_credit_blocked_len = vc["outport_credit_blocked_len"]
                outport_vc_blocked_len = vc["outport_vc_blocked_len"]
                outport_transfer_rate = [x * 4 / y for x, y in zip(outport_packet_len, outport_active_len)]
                outport_credit_constrained = [x / y for x, y in zip(outport_credit_blocked_len, outport_active_len)]
                outport_vc_constrained = [x / y for x, y in zip(outport_vc_blocked_len, outport_active_len)]
                outport_total_constrained_len = [x + y for x, y in zip(outport_credit_blocked_len, outport_vc_blocked_len)]
                outport_total_constrained = [(x + y) / z for x, y, z in zip(outport_credit_blocked_len, outport_vc_blocked_len, outport_active_len)]
                outport_transfer_rate_wo_overhead = [w * 4 / (x - y - z) for w, x, y, z in zip(outport_packet_len, outport_active_len, outport_credit_blocked_len, outport_vc_blocked_len)]

                avg_packet_len = numpy.average(outport_packet_len)
                avg_active_len = numpy.average(outport_active_len)
                avg_credit_blocked_len = numpy.average(outport_credit_blocked_len)
                avg_vc_blocked_len = numpy.average(outport_vc_blocked_len)
                avg_transfer_rate = numpy.average(outport_transfer_rate)
                transfer_rate_stdev = numpy.std(outport_transfer_rate)
                avg_credit_constrained = numpy.average(outport_credit_constrained)
                avg_vc_constrained = numpy.average(outport_vc_constrained)
                avg_total_constrained_len = numpy.average(outport_total_constrained_len)
                avg_total_constrained = numpy.average(outport_total_constrained)
                total_constrained_stdev = numpy.std(outport_total_constrained)
                avg_transfer_rate_wo_overhead = numpy.average(outport_transfer_rate_wo_overhead)
                transfer_rate_wo_overhead_stdev = numpy.std(outport_transfer_rate_wo_overhead)

                print(f"Statistics for outport {i}:{j}")
                print(f"Outport avg active len (cycles): {avg_active_len:.2f}")
                print(f"Outport avg packet len (flits): {avg_packet_len:.2f}")
                print(f"Outport transfer rate (inc. overhead): {avg_transfer_rate:.2f} +- {transfer_rate_stdev:.2f}B/cycle")
                print(f"Outport credit blocked len (cycles): {avg_credit_blocked_len:.2f}")
                print(f"Outport credit constrained: {100 * avg_credit_constrained:.2f}%")
                print(f"Outport vc blocked len (cycles): {avg_vc_blocked_len:.2f}")
                print(f"Outport vc constrained: {100 * avg_vc_constrained:.2f}%")
                print(f"Outport total blocked len (cycles): {avg_total_constrained_len:.2f}")
                print(f"Outport total constrained: {100 * avg_total_constrained:.2f} +- {100 * total_constrained_stdev:.2f}%")
                print(f"Outport transfer rate (w/o overhead): {avg_transfer_rate_wo_overhead:.2f} +- {transfer_rate_wo_overhead_stdev:.2f}B/cycle")
                print("")

if __name__ == "__main__":
    main()
