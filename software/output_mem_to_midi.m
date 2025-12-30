function output_mem_to_midi_constraint()
    clc; clear; close all;
    mem_filename = 'D:/WILLGAN/hardware/layers/output.mem';
    midi_filename = 'output_layer3_constraint.mid';
    base_note = 60;   % C4
    n_notes = 28;     % 2 oktav + 4 semitone
    tempo_bpm = 120;
    ticks_per_quarter = 96;

    % 1. Baca output.mem
    fid = fopen(mem_filename, 'r');
    hexVals = textscan(fid, '%s');
    fclose(fid);
    vals = hex2dec(hexVals{1});
    vals(vals >= 2^15) = vals(vals >= 2^15) - 2^16;
    vals = int16(vals);
    img = reshape(vals, 28, 28)'; % [time, pitch]

    % 2. Mapping ke MIDI
    % Nada: base_note + (0:27) = C4..F6
    % Waktu: tiap baris = 1/4 note
    velocities = min(max(abs(img) / max(abs(img(:))) * 127, 10), 127); % velocity dari magnitude
    velocities = round(velocities);

    % 3. Tulis MIDI
    fid = fopen(midi_filename, 'w', 'b');
    fwrite(fid, [77 84 104 100], 'uint8'); % 'MThd'
    fwrite(fid, 6, 'uint32');
    fwrite(fid, 0, 'uint16');
    fwrite(fid, 1, 'uint16');
    fwrite(fid, ticks_per_quarter, 'uint16');
    track_data = [];
    ticks_per_step = ticks_per_quarter / 4; % 1/4 note per step

    for t = 1:28
        for p = 1:28
            vel = velocities(t,p);
            if vel > 0
                note = base_note + (p-1);
                track_data = [track_data; 0; 144; note; vel]; % Note ON
                track_data = [track_data; ticks_per_step; 128; note; 0]; % Note OFF
            end
        end
    end
    track_data = [track_data; 0; 255; 47; 0];
    fwrite(fid, [77 84 114 107], 'uint8'); % 'MTrk'
    fwrite(fid, length(track_data), 'uint32');
    fwrite(fid, track_data, 'uint8');
    fclose(fid);

    fprintf('Success! MIDI file created: %s\n', midi_filename);
end