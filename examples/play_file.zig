const std = @import("std");
const ma = @import("miniaudio").ma;

pub fn main() !void {
    var device = std.mem.zeroes(ma.ma_device);
    var decoder = std.mem.zeroes(ma.ma_decoder);
    var res: ma.ma_result = 0;

    res = ma.ma_decoder_init_file("examples/assets/clearday.mp3", null, &decoder);
    // res = ma.ma_decoder_init_file_wav("examples/assets/clang-beat.wav", null, &decoder);
    // res = ma.ma_decoder_init_file_wav("examples/assets/clang.wav", null, &decoder);
    //res = ma.ma_decoder_init_file_wav("examples/assets/loop.wav", null, &decoder);
    defer _ = ma.ma_decoder_uninit(&decoder);
    if (res != 0) {
        std.debug.print("error: {}\n", .{res});
        return error.DecoderInitFailed;
    }

    var device_config = ma.ma_device_config_init(ma.ma_device_type_playback);
    device_config.playback.format = decoder.outputFormat;
    device_config.playback.channels = decoder.outputChannels;
    device_config.sampleRate = decoder.outputSampleRate;
    device_config.dataCallback = dataCallback;
    device_config.pUserData = &decoder;

    std.debug.print("{}, {}\n", .{decoder.outputFormat, decoder.outputSampleRate});

    res = ma.ma_device_init(null, &device_config, &device);
    defer ma.ma_device_uninit(&device);
    if (res != 0) {
        std.debug.print("error: {}\n", .{res});
        return error.InitFailed;
    }

    res = ma.ma_device_start(&device);
    if (res != 0) {
        std.debug.print("error: {}\n", .{res});
        return error.DeviceStartFailed;
    }

    std.time.sleep(std.time.ns_per_s * 3);
}

fn dataCallback(device: ?*ma.ma_device, out: ?*anyopaque, input: ?*const anyopaque, frame_count: ma.ma_uint32) callconv(.C) void {
    _ = input;

    var decoder = @intToPtr(*ma.ma_decoder, @ptrToInt(device.?.pUserData.?));
    _ = ma.ma_data_source_read_pcm_frames(decoder, out, frame_count, null);
}
