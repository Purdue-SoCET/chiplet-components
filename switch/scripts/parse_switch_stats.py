import sys
import json

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
            avg_latency = sum(latency) / len(latency)
            avg_active_time = sum(active_time) / len(active_time)
            avg_flits_per_packet = sum(flits_per_packet) / len(flits_per_packet)
            print(f"Statistics for buffer {i}")
            print(f"Average latency: {avg_latency}")
            print(f"Average active time: {avg_active_time}")
            print(f"Average time spent in pipe: {avg_latency - avg_active_time}")
            print(f"Average flits per packet: {avg_flits_per_packet}")
            print(f"Average cycles per flit: {avg_latency / avg_flits_per_packet}")
            print(f"Average crossbar cycles per flit: {avg_active_time / avg_flits_per_packet}")
            print("")

        for i, outport in enumerate(outport_stats):
            for j, vc in enumerate(outport):
                outport_total_len = vc["outport_total_len"]
                outport_packet_len = vc["outport_packet_len"]
                outport_credit_blocked_len = vc["outport_credit_blocked_len"]
                outport_vc_blocked_len = vc["outport_vc_blocked_len"]
                if len(outport_total_len) == 0:
                    continue
                outport_packet_len = sum(outport_packet_len) / len(outport_packet_len)
                outport_total_len = sum(outport_total_len) / len(outport_total_len)
                outport_credit_blocked_len = sum(outport_credit_blocked_len) / len(outport_credit_blocked_len)
                outport_vc_blocked_len = sum(outport_vc_blocked_len) / len(outport_vc_blocked_len)
                print(f"Statistics for outport {i}:{j}")
                print(f"Outport avg active len: {outport_total_len}")
                print(f"Outport avg packet len: {outport_packet_len}")
                print(f"Outport credit blocked len: {outport_credit_blocked_len}")
                print(f"Outport credit constrained: {100 * (outport_credit_blocked_len / outport_total_len):.2f}%")
                print(f"Outport vc blocked len: {outport_vc_blocked_len}")
                print(f"Outport vc constrained: {100 * (outport_vc_blocked_len / outport_total_len):.2f}%")
                print(f"Outport total blocked len: {outport_credit_blocked_len + outport_vc_blocked_len}")
                print(f"Outport total constrained: {100 * ((outport_credit_blocked_len + outport_vc_blocked_len) / outport_total_len):.2f}%")
                print("")

if __name__ == "__main__":
    main()
