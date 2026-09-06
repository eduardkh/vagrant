"""Read capabilities from each daemon; fail provisioning on an RPC error."""
import sys
import grpc

sys.path.insert(0, '/usr/local/share/frr-grpc')
import frr_northbound_pb2 as messages
import frr_northbound_pb2_grpc as services

for daemon, port in [('zebra', 50051), ('bgpd', 50052),
                     ('ospfd', 50053), ('staticd', 50054)]:
    with grpc.insecure_channel(f'127.0.0.1:{port}') as channel:
        grpc.channel_ready_future(channel).result(timeout=30)
        response = services.NorthboundStub(channel).GetCapabilities(
            messages.GetCapabilitiesRequest(), timeout=10)
        print(f'{daemon} ({port}): {response}')
