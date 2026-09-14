#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include <errno.h>

#define KLASOR_YOLU      "/home/mustafa/Documents/bitirme/digdes/deneme/den5/csv_design"
#define ALPHA            0.01
#define PI_CONST         3.14159265358979323846

/* -------------------------------------------------------------------------
 * Mathematical Helper Functions (Lanczos Gamma, gammaincc, ndtr)
 * ------------------------------------------------------------------------- */
static double log_gamma(double x) {
    double coef[7] = {
        0.99999999999980993, 676.52036812188514, -1259.1392167224028,
        771.32342877765313,  -176.61502916214059, 12.507343278686905,
        -0.13857109526572012
    };
    double y = x;
    double t = x + 7.5;
    double sum = coef[0];
    for (int i = 1; i < 7; i++) sum += coef[i] / (y + i);
    return 0.5 * log(2.0 * PI_CONST) + log(sum) - t + (y + 0.5) * log(t);
}

static double gammaincc(double a, double x) {
    if (x < 0.0 || a <= 0.0) return 0.0;
    if (x == 0.0) return 1.0;

    if (x < a + 1.0) {
        double ap = a, del = 1.0 / a, sum = del;
        while (fabs(del) > fabs(sum) * 1e-15) {
            ap += 1.0;
            del *= x / ap;
            sum += del;
        }
        return 1.0 - sum * exp(-x + a * log(x) - log_gamma(a));
    } else {
        double b = x + 1.0 - a, c = 1.0 / 1e-30, d = 1.0 / b, h = d;
        for (int i = 1; i <= 100; i++) {
            double an = -i * (i - a);
            b += 2.0;
            d = an * d + b;
            if (fabs(d) < 1e-30) d = 1e-30;
            c = b + an / c;
            if (fabs(c) < 1e-30) c = 1e-30;
            d = 1.0 / d;
            double del = d * c;
            h *= del;
            if (fabs(del - 1.0) < 1e-15) break;
        }
        return exp(-x + a * log(x) - log_gamma(a)) * h;
    }
}

static double normal_cdf(double x) {
    return 0.5 * erfc(-x / sqrt(2.0));
}

static void print_res(const char *name, double stat, double p, int pass) {
    printf("%-42s Stat: %10.4f  P-Val: %8.6f  [%s]\n",
           name, stat, p, (pass && p >= ALPHA) ? "GEÇTİ" : "KALDI");
}

/* -------------------------------------------------------------------------
 * Radix-2 FFT
 * ------------------------------------------------------------------------- */
static void fft_radix2(double *real, double *imag, int n) {
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
        if (i < j) {
            double tr = real[i]; real[i] = real[j]; real[j] = tr;
            double ti = imag[i]; imag[i] = imag[j]; imag[j] = ti;
        }
        int k = n >> 1;
        while (k <= j) { j -= k; k >>= 1; }
        j += k;
    }
    for (int len = 2; len <= n; len <<= 1) {
        double angle = -2.0 * PI_CONST / len;
        double wlen_r = cos(angle), wlen_i = sin(angle);
        for (int i = 0; i < n; i += len) {
            double w_r = 1.0, w_i = 0.0;
            for (int k = 0; k < len / 2; k++) {
                double u_r = real[i + k], u_i = imag[i + k];
                double v_r = real[i + k + len / 2] * w_r - imag[i + k + len / 2] * w_i;
                double v_i = real[i + k + len / 2] * w_i + imag[i + k + len / 2] * w_r;
                real[i + k] = u_r + v_r;
                imag[i + k] = u_i + v_i;
                real[i + k + len / 2] = u_r - v_r;
                imag[i + k + len / 2] = u_i - v_i;
                double next_w_r = w_r * wlen_r - w_i * wlen_i;
                w_i = w_r * wlen_i + w_i * wlen_r;
                w_r = next_w_r;
            }
        }
    }
}

/* -------------------------------------------------------------------------
 * 1. Frequency (Monobit) Test
 * ------------------------------------------------------------------------- */
void test_monobit(const uint8_t *bits, int n) {
    int s = 0;
    for (int i = 0; i < n; i++) s += 2 * bits[i] - 1;
    double s_obs = fabs((double)s) / sqrt((double)n);
    double p = erfc(s_obs / sqrt(2.0));
    print_res("1. Frequency (Monobit)", s_obs, p, 1);
}

/* -------------------------------------------------------------------------
 * 2. Frequency Test within a Block
 * ------------------------------------------------------------------------- */
void test_block_frequency(const uint8_t *bits, int n, int block_size) {
    int num_blocks = n / block_size;
    if (num_blocks == 0) return;
    double chi_sq = 0.0;
    for (int i = 0; i < num_blocks; i++) {
        int ones = 0;
        for (int j = 0; j < block_size; j++) ones += bits[i * block_size + j];
        double pi = (double)ones / (double)block_size;
        chi_sq += (pi - 0.5) * (pi - 0.5);
    }
    chi_sq *= 4.0 * block_size;
    double p = gammaincc((double)num_blocks / 2.0, chi_sq / 2.0);
    print_res("2. Block Frequency (M=128)", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 3. Runs Test
 * ------------------------------------------------------------------------- */
void test_runs(const uint8_t *bits, int n) {
    int ones = 0;
    for (int i = 0; i < n; i++) ones += bits[i];
    double pi = (double)ones / (double)n;
    if (fabs(pi - 0.5) >= (2.0 / sqrt((double)n))) {
        print_res("3. Runs (Monobit Precondition Failed)", 0.0, 0.0, 0);
        return;
    }
    int v_obs = 1;
    for (int i = 0; i < n - 1; i++) if (bits[i] != bits[i + 1]) v_obs++;
    double num = fabs((double)v_obs - 2.0 * n * pi * (1.0 - pi));
    double den = 2.0 * sqrt(2.0 * n) * pi * (1.0 - pi);
    double p = erfc(num / den);
    print_res("3. Runs", (double)v_obs, p, 1);
}

/* -------------------------------------------------------------------------
 * 4. Longest Run of Ones in a Block
 * ------------------------------------------------------------------------- */
void test_longest_run_of_ones(const uint8_t *bits, int n) {
    int m, k;
    double pi[7];
    if (n < 6272) {
        m = 8; k = 3;
        double p[4] = {0.2148, 0.3672, 0.2305, 0.1875};
        memcpy(pi, p, sizeof(p));
    } else if (n < 750000) {
        m = 128; k = 5;
        double p[6] = {0.1174, 0.2430, 0.2493, 0.1752, 0.1027, 0.1124};
        memcpy(pi, p, sizeof(p));
    } else {
        m = 10000; k = 6;
        double p[7] = {0.0882, 0.2092, 0.2483, 0.1933, 0.1208, 0.0675, 0.0727};
        memcpy(pi, p, sizeof(p));
    }
    int num_blocks = n / m;
    int *v = (int *)calloc(k + 1, sizeof(int));
    for (int i = 0; i < num_blocks; i++) {
        int max_r = 0, cur_r = 0;
        for (int j = 0; j < m; j++) {
            if (bits[i * m + j]) {
                cur_r++;
                if (cur_r > max_r) max_r = cur_r;
            } else cur_r = 0;
        }
        int b = 0;
        if (m == 8) b = (max_r <= 1) ? 0 : ((max_r == 2) ? 1 : ((max_r == 3) ? 2 : 3));
        else if (m == 128) b = (max_r <= 4) ? 0 : ((max_r >= 9) ? 5 : (max_r - 4));
        else b = (max_r <= 10) ? 0 : ((max_r >= 16) ? 6 : (max_r - 10));
        v[b]++;
    }
    double chi_sq = 0.0;
    for (int i = 0; i <= k; i++) {
        double exp_val = num_blocks * pi[i];
        chi_sq += ((v[i] - exp_val) * (v[i] - exp_val)) / exp_val;
    }
    free(v);
    double p = gammaincc((double)k / 2.0, chi_sq / 2.0);
    print_res("4. Longest Run of Ones", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 5. Binary Matrix Rank Test
 * ------------------------------------------------------------------------- */
static int gf2_rank(uint8_t mat[32][32]) {
    int rank = 0;
    for (int col = 0; col < 32; col++) {
        int pivot = -1;
        for (int row = rank; row < 32; row++) {
            if (mat[row][col]) { pivot = row; break; }
        }
        if (pivot != -1) {
            for (int k = 0; k < 32; k++) {
                uint8_t tmp = mat[rank][k];
                mat[rank][k] = mat[pivot][k];
                mat[pivot][k] = tmp;
            }
            for (int row = 0; row < 32; row++) {
                if (row != rank && mat[row][col]) {
                    for (int k = 0; k < 32; k++) mat[row][k] ^= mat[rank][k];
                }
            }
            rank++;
        }
        if (rank == 32) break;
    }
    return rank;
}

void test_binary_matrix_rank(const uint8_t *bits, int n) {
    int num_mat = n / 1024;
    if (num_mat == 0) return;
    int r32 = 0, r31 = 0, r_less = 0;
    uint8_t m[32][32];

    for (int idx = 0; idx < num_mat; idx++) {
        for (int r = 0; r < 32; r++) {
            for (int c = 0; c < 32; c++) {
                m[r][c] = bits[idx * 1024 + r * 32 + c];
            }
        }
        int rk = gf2_rank(m);
        if (rk == 32) r32++;
        else if (rk == 31) r31++;
        else r_less++;
    }

    double p32 = 0.2888 * num_mat;
    double p31 = 0.5776 * num_mat;
    double pl  = 0.1336 * num_mat;
    double chi_sq = ((r32 - p32) * (r32 - p32)) / p32 +
                    ((r31 - p31) * (r31 - p31)) / p31 +
                    ((r_less - pl) * (r_less - pl)) / pl;
    double p = exp(-chi_sq / 2.0);
    print_res("5. Binary Matrix Rank (32x32)", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 6. Discrete Fourier Transform (Spectral) Test
 * ------------------------------------------------------------------------- */
void test_spectral_dft(const uint8_t *bits, int n) {
    int p2 = 1;
    while ((p2 << 1) <= n) p2 <<= 1;
    if (p2 < 1024) return;

    double *real = (double *)malloc(p2 * sizeof(double));
    double *imag = (double *)calloc(p2, sizeof(double));
    for (int i = 0; i < p2; i++) real[i] = 2.0 * (double)bits[i] - 1.0;

    fft_radix2(real, imag, p2);

    double t = sqrt(2.995732274 * (double)p2);
    double n0 = 0.95 * (double)(p2 / 2 - 1);
    int n1 = 0;
    for (int i = 1; i < p2 / 2; i++) {
        double mag = sqrt(real[i] * real[i] + imag[i] * imag[i]);
        if (mag < t) n1++;
    }
    free(real);
    free(imag);

    double d = ((double)n1 - n0) / sqrt(((double)p2 * 0.95 * 0.05) / 4.0);
    double p = erfc(fabs(d) / sqrt(2.0));
    print_res("6. Discrete Fourier Transform (DFT)", d, p, 1);
}

/* -------------------------------------------------------------------------
 * 7. Non-overlapping Template Matching Test
 * ------------------------------------------------------------------------- */
void test_non_overlapping_template(const uint8_t *bits, int n, uint32_t tpl, int m, int num_blocks) {
    int blk_sz = n / num_blocks;
    double mu = (double)(blk_sz - m + 1) / pow(2.0, m);
    double var = (double)blk_sz * ((1.0 / pow(2.0, m)) - ((2.0 * m - 1) / pow(2.0, 2.0 * m)));
    double chi_sq = 0.0;

    for (int i = 0; i < num_blocks; i++) {
        int cnt = 0, j = 0;
        while (j <= blk_sz - m) {
            uint32_t pat = 0;
            for (int k = 0; k < m; k++) pat = (pat << 1) | bits[i * blk_sz + j + k];
            if (pat == tpl) { cnt++; j += m; }
            else j++;
        }
        chi_sq += ((double)cnt - mu) * ((double)cnt - mu) / var;
    }
    double p = gammaincc((double)num_blocks / 2.0, chi_sq / 2.0);
    print_res("7. Non-Overlapping Template (m=9)", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 8. Overlapping Template Matching Test
 * ------------------------------------------------------------------------- */
void test_overlapping_template(const uint8_t *bits, int n, int m, int blk_sz) {
    int num_blocks = n / blk_sz;
    if (num_blocks == 0) return;
    double pi[6] = {0.364091, 0.185659, 0.139381, 0.100571, 0.0704323, 0.139865};
    int v[6] = {0};

    for (int i = 0; i < num_blocks; i++) {
        int cnt = 0;
        for (int j = 0; j <= blk_sz - m; j++) {
            int match = 1;
            for (int k = 0; k < m; k++) {
                if (!bits[i * blk_sz + j + k]) { match = 0; break; }
            }
            if (match) cnt++;
        }
        if (cnt <= 4) v[cnt]++;
        else v[5]++;
    }

    double chi_sq = 0.0;
    for (int i = 0; i < 6; i++) {
        double exp_val = num_blocks * pi[i];
        chi_sq += ((v[i] - exp_val) * (v[i] - exp_val)) / exp_val;
    }
    double p = gammaincc(5.0 / 2.0, chi_sq / 2.0);
    print_res("8. Overlapping Template (m=9)", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 9. Maurer's Universal Statistical Test
 * ------------------------------------------------------------------------- */
void test_maurers_universal(const uint8_t *bits, int n) {
    if (n < 387840) {
        printf("%-42s Stat: %10.4f  P-Val: %8.6f  [ATLANDI: n < 387,840 bit]\n",
               "9. Maurer's Universal", 0.0, 0.0);
        return;
    }
    int l = (n >= 10342400) ? 10 : ((n >= 4654080) ? 9 : ((n >= 2068480) ? 8 : ((n >= 904960) ? 7 : 6)));
    int q = 10 * (1 << l);
    double exp_v[11] = {0, 0, 0, 0, 0, 0, 5.2177052, 6.1962507, 7.1836656, 8.1764248, 9.1723243};
    double var_v[11] = {0, 0, 0, 0, 0, 0, 2.954, 3.125, 3.238, 3.311, 3.356};

    int k = (n / l) - q;
    int num_pats = 1 << l;
    int *t_table = (int *)calloc(num_pats, sizeof(int));

    for (int i = 0; i < q; i++) {
        int idx = 0;
        for (int b = 0; b < l; b++) idx = (idx << 1) | bits[i * l + b];
        t_table[idx] = i + 1;
    }

    double sum_log = 0.0;
    for (int i = q; i < q + k; i++) {
        int idx = 0;
        for (int b = 0; b < l; b++) idx = (idx << 1) | bits[i * l + b];
        sum_log += log2((double)((i + 1) - t_table[idx]));
        t_table[idx] = i + 1;
    }
    free(t_table);

    double fn = sum_log / (double)k;
    double c = 0.7 - (0.8 / (double)l) + (4.0 + 32.0 / (double)l) * pow((double)k, -3.0 / (double)l) / 15.0;
    double sigma = c * sqrt(var_v[l] / (double)k);
    double p = erfc(fabs(fn - exp_v[l]) / (sqrt(2.0) * sigma));
    print_res("9. Maurer's Universal Statistical", fn, p, 1);
}

/* -------------------------------------------------------------------------
 * 10. Linear Complexity (Berlekamp-Massey) Test
 * ------------------------------------------------------------------------- */
static int berlekamp_massey(const uint8_t *blk, int m) {
    uint8_t *b = (uint8_t *)calloc(m, sizeof(uint8_t));
    uint8_t *c = (uint8_t *)calloc(m, sizeof(uint8_t));
    uint8_t *t = (uint8_t *)calloc(m, sizeof(uint8_t));
    b[0] = 1; c[0] = 1;
    int l = 0, m_val = -1;

    for (int step = 0; step < m; step++) {
        uint8_t d = blk[step];
        for (int j = 1; j <= l; j++) d ^= (c[j] & blk[step - j]);
        if (d) {
            memcpy(t, c, m);
            int shift = step - m_val;
            for (int j = 0; j < m - shift; j++) c[j + shift] ^= b[j];
            if (l <= step / 2) {
                l = step + 1 - l;
                m_val = step;
                memcpy(b, t, m);
            }
        }
    }
    free(b); free(c); free(t);
    return l;
}

void test_linear_complexity(const uint8_t *bits, int n, int m) {
    int num_blocks = n / m;
    if (num_blocks == 0) return;
    double mu = ((double)m / 2.0) + (4.0 + (double)(m % 2)) / 36.0;
    double pi[7] = {0.01047, 0.03125, 0.12500, 0.50000, 0.25000, 0.06250, 0.02078};
    int v[7] = {0};

    for (int i = 0; i < num_blocks; i++) {
        int lc = berlekamp_massey(&bits[i * m], m);
        double t_val = ((m % 2 == 0) ? 1.0 : -1.0) * ((double)lc - mu) + (2.0 / 9.0);
        if (t_val <= -2.5) v[0]++;
        else if (t_val <= -1.5) v[1]++;
        else if (t_val <= -0.5) v[2]++;
        else if (t_val <= 0.5)  v[3]++;
        else if (t_val <= 1.5)  v[4]++;
        else if (t_val <= 2.5)  v[5]++;
        else v[6]++;
    }

    double chi_sq = 0.0;
    for (int i = 0; i < 7; i++) {
        double exp_val = num_blocks * pi[i];
        chi_sq += ((v[i] - exp_val) * (v[i] - exp_val)) / exp_val;
    }
    double p = gammaincc(3.0, chi_sq / 2.0);
    print_res("10. Linear Complexity (M=500)", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 11. Serial Test
 * ------------------------------------------------------------------------- */
static double psi_sq(const uint8_t *bits, int n, int m) {
    if (m <= 0) return 0.0;
    int num_pats = 1 << m;
    int *counts = (int *)calloc(num_pats, sizeof(int));
    for (int i = 0; i < n; i++) {
        int idx = 0;
        for (int j = 0; j < m; j++) idx = (idx << 1) | bits[(i + j) % n];
        counts[idx]++;
    }
    double sum = 0.0;
    for (int i = 0; i < num_pats; i++) sum += (double)counts[i] * (double)counts[i];
    free(counts);
    return ((double)num_pats / (double)n) * sum - (double)n;
}

void test_serial(const uint8_t *bits, int n, int m) {
    double psim  = psi_sq(bits, n, m);
    double psim1 = psi_sq(bits, n, m - 1);
    double psim2 = psi_sq(bits, n, m - 2);

    double del1 = psim - psim1;
    double del2 = psim - 2.0 * psim1 + psim2;

    double p1 = gammaincc(pow(2.0, m - 2), del1 / 2.0);
    double p2 = gammaincc(pow(2.0, m - 3), del2 / 2.0);

    print_res("11. Serial (m=3, Delta 1)", del1, p1, 1);
    print_res("11. Serial (m=3, Delta 2)", del2, p2, 1);
}

/* -------------------------------------------------------------------------
 * 12. Approximate Entropy Test
 * ------------------------------------------------------------------------- */
void test_approximate_entropy(const uint8_t *bits, int n, int m) {
    if (m > (int)floor(log2(n)) - 5) m = (int)floor(log2(n)) - 5;
    if (m < 2) return;

    double phi[2] = {0.0, 0.0};
    for (int step = 0; step < 2; step++) {
        int cur_m = m + step;
        int num_pats = 1 << cur_m;
        int *counts = (int *)calloc(num_pats, sizeof(int));
        for (int i = 0; i < n; i++) {
            int pat = 0;
            for (int j = 0; j < cur_m; j++) pat = (pat << 1) | bits[(i + j) % n];
            counts[pat]++;
        }
        double sum = 0.0;
        for (int i = 0; i < num_pats; i++) {
            if (counts[i] > 0) {
                double c = (double)counts[i] / (double)n;
                sum += c * log(c);
            }
        }
        phi[step] = sum;
        free(counts);
    }

    double apen = phi[0] - phi[1];
    double chi_sq = 2.0 * n * (log(2.0) - apen);
    double p = gammaincc(pow(2.0, m - 1), chi_sq / 2.0);
    print_res("12. Approximate Entropy (m=10)", chi_sq, p, 1);
}

/* -------------------------------------------------------------------------
 * 13. Cumulative Sums Test
 * ------------------------------------------------------------------------- */
static void run_cusum(const uint8_t *bits, int n, int rev, const char *label) {
    int max_s = 0, cur_s = 0;
    for (int i = 0; i < n; i++) {
        int b = rev ? bits[n - 1 - i] : bits[i];
        cur_s += (b ? 1 : -1);
        if (abs(cur_s) > max_s) max_s = abs(cur_s);
    }
    double z = (double)max_s;
    double sum1 = 0.0, sum2 = 0.0;
    int k_start1 = (int)floor((-n / z + 1.0) / 4.0);
    int k_end1   = (int)floor((n / z - 1.0) / 4.0);
    for (int k = k_start1; k <= k_end1; k++) {
        double t1 = (4.0 * k + 1.0) * z / sqrt(n);
        double t2 = (4.0 * k - 1.0) * z / sqrt(n);
        sum1 += normal_cdf(t1) - normal_cdf(t2);
    }
    int k_start2 = (int)floor((-n / z - 3.0) / 4.0);
    int k_end2   = (int)floor((n / z - 1.0) / 4.0);
    for (int k = k_start2; k <= k_end2; k++) {
        double t1 = (4.0 * k + 3.0) * z / sqrt(n);
        double t2 = (4.0 * k + 1.0) * z / sqrt(n);
        sum2 += normal_cdf(t1) - normal_cdf(t2);
    }
    double p = 1.0 - sum1 + sum2;
    print_res(label, z, p, 1);
}

void test_cumulative_sums(const uint8_t *bits, int n) {
    run_cusum(bits, n, 0, "13. Cumulative Sums (Forward)");
    run_cusum(bits, n, 1, "13. Cumulative Sums (Reverse)");
}

/* -------------------------------------------------------------------------
 * 14. Random Excursions Test & 15. Random Excursions Variant Test
 * ------------------------------------------------------------------------- */
void test_random_excursions_both(const uint8_t *bits, int n) {
    int *s = (int *)malloc((n + 1) * sizeof(int));
    s[0] = 0;
    for (int i = 0; i < n; i++) s[i + 1] = s[i] + (bits[i] ? 1 : -1);

    int *zero_indices = (int *)malloc((n + 2) * sizeof(int));
    int j = 0;
    for (int i = 0; i <= n; i++) {
        if (s[i] == 0) zero_indices[j++] = i;
    }
    j--; // Number of cycles

    if (j < 500) {
        printf("%-42s Stat: %10.4f  P-Val: %8.6f  [ATLANDI: J=%d < 500 (En az 1M bit önerilir)]\n",
               "14/15. Random Excursions", 0.0, 0.0, j);
        free(s); free(zero_indices);
        return;
    }

    /* 14. Random Excursions */
    int states8[8] = {-4, -3, -2, -1, 1, 2, 3, 4};
    double pi_vals[5][6] = {
        {0, 0, 0, 0, 0, 0},
        {0.5000, 0.2500, 0.1250, 0.0625, 0.0312, 0.0312},
        {0.7500, 0.0625, 0.0469, 0.0352, 0.0264, 0.0791},
        {0.8333, 0.0278, 0.0231, 0.0193, 0.0161, 0.0804},
        {0.8750, 0.0156, 0.0137, 0.0120, 0.0105, 0.0732}
    };

    for (int idx = 0; idx < 8; idx++) {
        int x = states8[idx];
        int v[6] = {0};
        for (int cycle = 0; cycle < j; cycle++) {
            int cnt = 0;
            for (int k = zero_indices[cycle]; k < zero_indices[cycle + 1]; k++) {
                if (s[k] == x) cnt++;
            }
            if (cnt <= 4) v[cnt]++;
            else v[5]++;
        }
        double chi_sq = 0.0;
        for (int c = 0; c < 6; c++) {
            double exp_val = (double)j * pi_vals[abs(x)][c];
            chi_sq += ((v[c] - exp_val) * (v[c] - exp_val)) / exp_val;
        }
        double p = gammaincc(5.0 / 2.0, chi_sq / 2.0);
        char lbl[64];
        snprintf(lbl, sizeof(lbl), "14. Random Excursions (x=%+d)", x);
        print_res(lbl, chi_sq, p, 1);
    }

    /* 15. Random Excursions Variant */
    for (int x = -9; x <= 9; x++) {
        if (x == 0) continue;
        int total_k = 0;
        for (int i = 0; i <= n; i++) if (s[i] == x) total_k++;
        double num = fabs((double)total_k - (double)j);
        double den = sqrt(2.0 * (double)j * (4.0 * abs(x) - 2.0));
        double p = erfc(num / den);
        char lbl[64];
        snprintf(lbl, sizeof(lbl), "15. Random Excursions Var (x=%+d)", x);
        print_res(lbl, (double)total_k, p, 1);
    }

    free(s);
    free(zero_indices);
}

/* -------------------------------------------------------------------------
 * CSV Loader & Master Driver
 * ------------------------------------------------------------------------- */
int main(void) {
    int start_idx, end_idx;
    printf("=================================================================\n");
    printf("   TAM NIST SP 800-22 Rev 1a Test Paketi (15 Testin Tumu - C99)   \n");
    printf("=================================================================\n");

    printf("Baslangic dosya numarasi (Orn: 100): ");
    if (scanf("%d", &start_idx) != 1) return 1;
    printf("Bitis dosya numarasi (Orn: 150): ");
    if (scanf("%d", &end_idx) != 1) return 1;

    size_t cap = 4000000;
    size_t total_bits = 0;
    uint8_t *bit_stream = (uint8_t *)malloc(cap);

    printf("\n[+] ILA CSV dosyalari birlestiriliyor (%d -> %d)...\n", start_idx, end_idx);

    char path[512], line[256];
    int files_read = 0;

    for (int idx = start_idx; idx <= end_idx; idx++) {
        snprintf(path, sizeof(path), "%s/iladata%d_word.csv", KLASOR_YOLU, idx);
        FILE *f = fopen(path, "r");
        if (!f) continue;

        while (fgets(line, sizeof(line), f)) {
            char *tok = strtok(line, ",\r\n\t ");
            if (!tok || tok[0] == '#' || tok[0] == 'S' || tok[0] == 's') continue;

            char *end;
            uint32_t val = (uint32_t)strtoul(tok, &end, 16);
            if (tok == end) continue;

            if (total_bits + 32 >= cap) {
                cap *= 2;
                bit_stream = (uint8_t *)realloc(bit_stream, cap);
            }

            for (int b = 31; b >= 0; b--) {
                bit_stream[total_bits++] = (val >> b) & 1;
            }
        }
        fclose(f);
        files_read++;
    }

    if (total_bits == 0) {
        fprintf(stderr, "HATA: Veri okunamadi. Dosya yollarini ve probe adini kontrol edin.\n");
        free(bit_stream);
        return 1;
    }

    printf("[+] Okunan dosya sayisi : %d\n", files_read);
    printf("[+] Toplam test verisi  : %zu bit (%.2f Megabits)\n\n", total_bits, (double)total_bits / 1e6);

    printf("========================================================================================\n");
    printf("%-42s %-16s %-16s %s\n", "TEST ADI", "ISTATISTIK", "P-DEGERI", "SONUC");
    printf("========================================================================================\n");

    int n = (int)total_bits;

    test_monobit(bit_stream, n);
    test_block_frequency(bit_stream, n, 128);
    test_runs(bit_stream, n);
    test_longest_run_of_ones(bit_stream, n);
    test_binary_matrix_rank(bit_stream, n);
    test_spectral_dft(bit_stream, n);
    test_non_overlapping_template(bit_stream, n, 0x001, 9, 8); // 000000001 pattern
    test_overlapping_template(bit_stream, n, 9, 1032);
    test_maurers_universal(bit_stream, n);
    test_linear_complexity(bit_stream, n, 500);
    test_serial(bit_stream, n, 3);
    test_approximate_entropy(bit_stream, n, 10);
    test_cumulative_sums(bit_stream, n);
    test_random_excursions_both(bit_stream, n);

    printf("========================================================================================\n");

    free(bit_stream);
    return 0;
}
