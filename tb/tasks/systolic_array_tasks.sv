//--------------------------
// Library of common tasks for the systolic array TB
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

task init_zero_arrays;
// Initialize all arrays to zero
for (int i = 0; i < M_ROWS; i++) begin
    for (int j = 0; j < N_COLS; j++) begin
    track_acc_out[i][j] = '0;
    track_a_reg[i][j] = '0;
    track_b_reg[i][j] = '0;
    end
end
// Initialize input arrays
for (int i = 0; i < M_ROWS; i++) begin
    array_a_i[i] = '0;
end
for (int i = 0; i < N_COLS; i++) begin
    array_b_i[i] = '0;
end
endtask

// Generate random data
task rand_gen_array_a;
for (int i = 0; i < M_ROWS; i++) begin
    array_a_i[i] = $urandom_range(100);
end
endtask

task rand_gen_array_b;
for (int i = 0; i < N_COLS; i++) begin
    array_b_i[i] = $urandom_range(100);
end
endtask

// Feeding data to tracker
task feed_tracker_a;
// Need to start from the end
for (int i = 0; i < M_ROWS; i++) begin
    for (int j = N_COLS-1; j > -1; j--) begin
    if (j == 0) begin
        track_a_reg[i][j] = array_a_i[i];
    end else begin
        track_a_reg[i][j] = track_a_reg[i][j-1];
    end
    end
end
endtask

task feed_tracker_b;
for (int i = M_ROWS-1; i > -1; i--) begin
    for (int j = 0; j < N_COLS; j++) begin
    if (i == 0) begin
        track_b_reg[i][j] = array_b_i[j];
    end else begin
        track_b_reg[i][j] = track_b_reg[i-1][j];
    end
    end
end
endtask

task update_acc_tracker;
for (int i = 0; i < M_ROWS; i++) begin
    for (int j = 0; j < N_COLS; j++) begin
    track_acc_out[i][j] += track_a_reg[i][j] * track_b_reg[i][j];
    end
end
endtask
