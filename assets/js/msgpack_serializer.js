import { encode, decode } from "@msgpack/msgpack";

export function encodeM(msg, callback){
    let payload = [
        msg.join_ref, msg.ref, msg.topic, msg.event, msg.payload
    ];
    return callback(encode(payload))
}

export function decodeM(rawPayload, callback) {
    let [join_ref, ref, topic, event, payload] = decode(rawPayload);
    return callback({join_ref, ref, topic, event, payload})
}
