address = 0x8000
data = []
while address <= 0xffff
    byte = case address
        when 0xfffc
            0x00
        when 0xfffd
            0x80
        when 0x8010
            0x4c
        when 0x8011
            0x01
        when 0x8012
            0x80
        else
            0xea
        end
    data.push(byte)
    address += 1
end

File.binwrite("prog.bin", data.pack("C*"))