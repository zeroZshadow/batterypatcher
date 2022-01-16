const std = @import("std");

pub fn PatchParameters(comptime baseType: type) type {
    // zig fmt: off
    return typeblk: {
        var baseFields = std.meta.fields(baseType);
        var typeInfo = std.builtin.TypeInfo{
            .Struct = .{
                .layout = .Auto,
                .decls = &[_]std.builtin.TypeInfo.Declaration{},
                .is_tuple = false,
                .fields = fieldblk: {
                    var fields: [baseFields.len] std.builtin.TypeInfo.StructField = undefined;
                    inline for (baseFields) |field, i| {
                        fields[i] = .{
                            .name = field.name,
                            .field_type = u32,
                            .is_comptime = false,
                            .alignment = 0,
                            .default_value = null
                        };
                    }
                    break :fieldblk &fields;
                }
            }
        };
        break :typeblk @Type(typeInfo);
    };
    // zig fmt: on
}

pub fn PatchWriter(comptime dataOffsets: anytype, comptime patch: anytype) type {
    const bytes = @embedFile(patch);
    const parametersType = PatchParameters(@TypeOf(dataOffsets));

    return struct {
        pub fn writePatch(parameters: parametersType, rom: []u8, targetOffset: u32) void {
            std.mem.copy(u8, rom[targetOffset..], bytes);

            const endOffset = bytes.len + targetOffset;

            inline for (@typeInfo(parametersType).Struct.fields) |field| {
                const offset = endOffset - @field(dataOffsets, field.name);
                const value = @field(parameters, field.name);

                std.mem.writeIntSlice(u32, rom[offset .. offset + 4], value, .Little);
            }
        }
    };
}
