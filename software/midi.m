function fpga_to_midi_converter()
    clc; clear; close all;
    
    % ================= CONFIGURATION =================
    mem_filename = 'output_wgan.mem'; 
    midi_filename = 'fpga_music.mid'; 
    
    % Konfigurasi Mapping Q6.10 ke Piano
    center_note = 60;       % Middle C
    note_scale = 10;        % Scaling factor
    tempo_bpm = 120;
    % =================================================
    
    %% 1. READ / GENERATE DATA
    if exist(mem_filename, 'file')
        fprintf('Reading from %s...\n', mem_filename);
        fid = fopen(mem_filename, 'r');
        raw_hex = textscan(fid, '%s');
        fclose(fid);
        hex_data = raw_hex{1};
    else
        fprintf('Warning: %s not found. Generating RANDOM dummy data...\n', mem_filename);
        % Generate random Hex Q6.10 (dummy data 16-bit)
        dummy_vals = randi([0, 65535], 64, 1); 
        hex_data = dec2hex(dummy_vals, 4);
        
        % Simpan file dummy agar Anda bisa melihat formatnya
        fid = fopen(mem_filename, 'w');
        for i=1:length(hex_data)
            fprintf(fid, '%s\n', hex_data(i,:));
        end
        fclose(fid);
    end

    %% 2. PARSE Q6.10 FIXED POINT TO FLOAT
    dec_data = hex2dec(hex_data);
    
    % Handle Signed 16-bit Two's Complement
    idx_negative = dec_data >= 32768; % 0x8000
    dec_data(idx_negative) = dec_data(idx_negative) - 65536;
    
    % Convert to Float (Divide by 2^10 because Q6.10)
    float_data = dec_data / 1024.0;
    
    fprintf('Data Sample (Float): [%.2f, %.2f, %.2f ...]\n', float_data(1:3));

    %% 3. MAP TO MIDI NOTES
    midi_notes = round(float_data * note_scale + center_note);
    
    % Clamp range (Piano 21-108)
    midi_notes(midi_notes < 21) = 21;
    midi_notes(midi_notes > 108) = 108;
    
    velocities = ones(size(midi_notes)) * 100; 
    durations = ones(size(midi_notes)) * 0.5;  

    %% 4. WRITE MIDI FILE
    write_simple_midi(midi_filename, midi_notes, velocities, durations, tempo_bpm);
    fprintf('Success! MIDI file created: %s\n', midi_filename);

    %% 5. PLAY MIDI
    fprintf('Playing MIDI file...\n');
    if ispc
        winopen(midi_filename);
    elseif ismac
        system(['open ' midi_filename]);
    else
        fprintf('File saved. Open %s manually to listen.\n', midi_filename);
    end
end

%% ================= HELPER FUNCTION: MIDI WRITER =================
function write_simple_midi(filename, notes, vels, durs, bpm)
    fid = fopen(filename, 'w', 'b'); 
    
    % --- Header Chunk ---
    fwrite(fid, [77 84 104 100], 'uint8'); % 'MThd'
    fwrite(fid, 6, 'uint32');              % Length
    fwrite(fid, 0, 'uint16');              % Format 0
    fwrite(fid, 1, 'uint16');              % Tracks
    fwrite(fid, 96, 'uint16');             % Ticks per quarter note
    
    % --- Track Chunk Data ---
    track_data = [];
    ticks_per_sec = (96 * bpm) / 60;
    
    for i = 1:length(notes)
        note = notes(i);
        vel = vels(i);
        
        % FIX: Menggunakan variabel yang benar (ticks_per_sec)
        dur_ticks = round(durs(i) * ticks_per_sec);
        
        % Simple Write Logic (Tanpa Variable Length Quantity yg rumit)
        % Kita limit durasi agar muat di 1 byte (max 127 ticks)
        % agar script tetap pendek dan tidak error.
        if dur_ticks > 127, dur_ticks = 127; end
        if dur_ticks < 1, dur_ticks = 1; end
        
        % Note ON (Delta Time 0) -> 00 90 Note Vel
        track_data = [track_data; 0; 144; note; vel]; 
        
        % Note OFF (Delta Time = dur_ticks) -> Dur 80 Note 00
        track_data = [track_data; dur_ticks; 128; note; 0];
    end
    
    % End of Track
    track_data = [track_data; 0; 255; 47; 0];
    
    % --- Write Track Chunk ---
    fwrite(fid, [77 84 114 107], 'uint8'); % 'MTrk'
    fwrite(fid, length(track_data), 'uint32');
    fwrite(fid, track_data, 'uint8');
    
    fclose(fid);
end