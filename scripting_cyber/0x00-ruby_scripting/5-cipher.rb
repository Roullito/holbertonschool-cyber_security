#!/usr/bin/env ruby

class CaesarCipher
    def initialize(shift)
        @shift = shift
    end

    def encrypt(message)
        cipher(message, @shift)
    end

    def decrypt(message)
        cipher(message, -@shift)
    end

    private

    def cipher(message, shift)
        message.chars.map do |char|
            if char.between?('a', 'z')
                base = 'a'.ord
                ((char.ord - base + shift) % 26 + base).chr
            elsif char.between?('A', 'Z')
                base = 'A'.ord
                ((char.ord - base + shift) % 26 + base).chr
            else
                char
            end
        end.join
    end
end