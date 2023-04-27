#include <iostream>
#include <chrono>
#include <vector>
#include <cmath>
#include <random>
#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <numeric>

constexpr int POPULATION_SIZE = 30;
constexpr int COMBINATIONAL_CROSSING_SIZE = 104400;
constexpr int MAX_POPULATION_SIZE = 109890;
constexpr int CHROMOSOMES_SIZE = 183;
constexpr int MAX_POOL = 30;
constexpr int MAX_ITERATIONS = 3;

void initialize(int**& population, int* original, double*& dists, double*& sorted, int**& closest)
{
    srand(time(NULL));
    int x = 0;
    for (int i = 0; i < POPULATION_SIZE; i++)
    {
        for (int j = 0; j < CHROMOSOMES_SIZE; j++)
        {
            population[i][j] = x % 55;
            dists[i] += pow(original[j] - population[i][j], 2);
            x++;
        }
        dists[i] = sqrt(dists[i]);
        sorted[i] = dists[i];
    }

    std::sort(sorted, sorted + POPULATION_SIZE);

    for (int i = 0; i < MAX_POOL; i++)
    {
        for (int j = 0; j < CHROMOSOMES_SIZE; j++) closest[i][j] = population[std::distance(dists, std::find(dists, dists + POPULATION_SIZE, sorted[i]))][j];
    }
    printf("ISorted3 = %2.4f\tSum = %2.4f\n", sorted[0], std::accumulate(sorted, sorted + POPULATION_SIZE, 0.0));

}

void get_distances(int**& population, int* original, double*& distances, double*& sorted)
{
    for (int i = 0; i < MAX_POPULATION_SIZE; i++)
    {
        distances[i] = 0;
        for (int j = 0; j < CHROMOSOMES_SIZE; j++)
        {
            distances[i] += pow(original[j] - population[i][j], 2);
        }
        distances[i] = sqrt(distances[i]);
        sorted[i] = distances[i];
    }
}

void get_closest_distances(int**& population, int**& closest, double*& distances, double*& sorted)
{
    int iteration = 1;
    std::sort(sorted, sorted + MAX_POPULATION_SIZE);
    for (int i = 0; i < MAX_POOL; i++)
    {
        auto index = std::distance(distances, std::find(distances, distances + MAX_POPULATION_SIZE, sorted[i]));
        for (int j = 0; j < CHROMOSOMES_SIZE; j++)
        {
            closest[i][j] = population[index][j];
        }
    }
    // printf("Sorted = %2.4f\tSum = %2.4f\n", sorted[0], std::accumulate(sorted, sorted + MAX_POPULATION_SIZE, 0.0));
    iteration++;
}

void combinational_crossing(int**& population, int**& closest)
{
    auto inner_count = 0;

    for (int i = 0; i < MAX_POOL; i++)
    {
        auto N = 0;
        for (int j = i + 1; j < MAX_POOL; j++)
        {
            // printf("I: %d\tJ: %d\tCount: %d\tInnerCount: %d\n", i, j, N, inner_count);
            for (int p = 0; p < 60; p++)
            {
                for (int x = 0; x < CHROMOSOMES_SIZE; x++)
                {
                    population[inner_count + 0][x] = closest[i][x];
                    population[inner_count + 1][x] = closest[j][x];
                    population[inner_count + 2][x] = closest[i][x];
                    population[inner_count + 3][x] = closest[j][x];
                }

                population[inner_count + 0][3 * p + 0] = closest[j][3 * p + 3];
                population[inner_count + 0][3 * p + 1] = closest[j][3 * p + 4];
                population[inner_count + 0][3 * p + 2] = closest[j][3 * p + 5];

                population[inner_count + 1][3 * p + 0] = closest[i][3 * p + 3];
                population[inner_count + 1][3 * p + 1] = closest[i][3 * p + 4];
                population[inner_count + 1][3 * p + 2] = closest[i][3 * p + 5];

                population[inner_count + 2][3 * p + 3] = closest[j][3 * p + 0];
                population[inner_count + 2][3 * p + 4] = closest[j][3 * p + 1];
                population[inner_count + 2][3 * p + 5] = closest[j][3 * p + 2];

                population[inner_count + 3][3 * p + 3] = closest[i][3 * p + 0];
                population[inner_count + 3][3 * p + 4] = closest[i][3 * p + 1];
                population[inner_count + 3][3 * p + 5] = closest[i][3 * p + 2];

                inner_count += 4;
                N += 4;
            }
        }
    }
}

void mutate(int**& population, int**& closest, int offset)
{
    auto x = offset;
    for (int i = 0; i < MAX_POOL; i++)
    {
        for (int j = 0; j < CHROMOSOMES_SIZE; j++)
        {
            for (int k = 0; k < 183; k++) population[x][k] = closest[i][k];
            population[x][j] = j % 55;
            x++;
        }
    }
}

bool check(int* original, int**& population)
{
    for (int i = 0; i < MAX_POPULATION_SIZE; i++)
    {
        for (int j = 0; j < CHROMOSOMES_SIZE; j++)
        {
            if (population[i][j] != original[j]) break;
            if (j == CHROMOSOMES_SIZE - 1)
            {
                printf("Match Found at population %d\n", i); return true;
            }
        }
    }
    return false;
}

__device__ double get_euclidean_distance(int* sample, int* original)
{
    auto tid = threadIdx.x;
    __shared__ int s_dist[256];
    if (tid < 183)
    {
        s_dist[tid] = (original[tid] - sample[tid]);
        s_dist[tid] = s_dist[tid] * s_dist[tid];
    }
    __syncthreads();
    for (int s = 128; s > 0; s >>= 1)
    {
        if (tid < s)
        {
            s_dist[tid] += s_dist[tid + s];
        }
        __syncthreads();
    }
    return s_dist[0];
}

__global__ void get_distances_gpu(int** population, int* original, double* dist)
{
    auto x = sqrt(get_euclidean_distance(population[blockIdx.x], original));
    if (blockIdx.x < 10 && threadIdx.x == 0) printf("Distance is %2.4f\n", x);
    dist[blockIdx.x] = x;
}

__global__ void combinational_crossing_gpu(int** population, int** closest)
{
    int i = blockIdx.x;
    int j = threadIdx.x;
    int offset = 0;
    for (int I = 0; I < i; I++)
        offset += 240 * (blockDim.x - (i + 1));

    if (j > i && i == 0)
    {
        printf("Thread: %d\t%d + %d\n", j, offset, 240 * (j - i - 1));
        offset += 240 * (j - i - 1);
        for (int p = 0; p < 60; p++)
        {
            for (int x = 0; x < CHROMOSOMES_SIZE; x++)
            {
                population[offset + 0][x] = closest[i][x];
                population[offset + 1][x] = closest[j][x];
                population[offset + 2][x] = closest[i][x];
                population[offset + 3][x] = closest[j][x];
            }

            population[offset + 0][3 * p + 0] = closest[j][3 * p + 3];
            population[offset + 0][3 * p + 1] = closest[j][3 * p + 4];
            population[offset + 0][3 * p + 2] = closest[j][3 * p + 5];

            population[offset + 1][3 * p + 0] = closest[i][3 * p + 3];
            population[offset + 1][3 * p + 1] = closest[i][3 * p + 4];
            population[offset + 1][3 * p + 2] = closest[i][3 * p + 5];

            population[offset + 2][3 * p + 3] = closest[j][3 * p + 0];
            population[offset + 2][3 * p + 4] = closest[j][3 * p + 1];
            population[offset + 2][3 * p + 5] = closest[j][3 * p + 2];

            population[offset + 3][3 * p + 3] = closest[i][3 * p + 0];
            population[offset + 3][3 * p + 4] = closest[i][3 * p + 1];
            population[offset + 3][3 * p + 5] = closest[i][3 * p + 2];

            offset += 4;
        }
    }
}

int main()
{
    srand(time(NULL));

    //Host Initializations
    double* distances = new double[MAX_POPULATION_SIZE];
    double* sorted = new double[MAX_POPULATION_SIZE];
    int** population = new int* [MAX_POPULATION_SIZE];
    int** closest = new int* [MAX_POOL];

    int iterations = 0;
    for (int i = 0; i < MAX_POPULATION_SIZE; i++) population[i] = new int[CHROMOSOMES_SIZE];
    for (int i = 0; i < MAX_POOL; i++) closest[i] = new int[CHROMOSOMES_SIZE];

    int original[] = { 1, 0, 1, 2, 10, 1, 4, 5, 6, 11, 3, 7, 8, 12, 0, 4, 6, 8, 13, 1, 5, 7, 14, 0,
           2, 3, 15, 0, 4, 8, 9, 16, 1, 6, 8, 9, 17, 0, 4, 6, 9, 18, 0, 13, 9, 19, 0, 10,
           3, 20, 0, 29, 47, 21, 0, 17, 4, 22, 4, 9, 23, 0, 30, 12, 24, 4, 39, 25, 0, 49, 14, 26,
           0, 25, 4, 9, 27, 2, 21, 50, 28, 2, 43, 37, 29, 0, 11, 20, 23, 30, 4, 2, 31, 3, 39, 19,
           32, 0, 47, 38, 33, 0, 16, 25, 41, 34, 0, 26, 47, 35, 0, 27, 18, 39, 36, 0, 52, 54, 37, 2,
           46, 15, 38, 0, 3, 31, 39, 2, 16, 22, 40, 4, 6, 41, 2, 35, 50, 42, 1, 2, 3, 43, 4, 0,
           44, 4, 8, 45, 0, 32, 14, 46, 4, 1, 47, 0, 40, 39, 48, 0, 34, 40, 49, 0, 25, 1, 50, 0,
           42, 44, 51, 0, 14, 45, 52, 0, 28, 44, 53, 2, 27, 36, 54 };

    initialize(population, original, distances, sorted, closest);
    combinational_crossing(population, closest);
    mutate(population, closest, COMBINATIONAL_CROSSING_SIZE);

    //Device Initializations
    double* d_distances;
    double* d_sorted;
    int* d_original;
    int** d_population;
    int** d_closest;

    cudaMalloc((void**)&d_distances, MAX_POPULATION_SIZE * sizeof(double*));
    cudaMalloc((void**)&d_sorted, MAX_POPULATION_SIZE * sizeof(double*));
    cudaMalloc((void**)&d_original, CHROMOSOMES_SIZE * sizeof(int*));
    cudaMalloc((void**)&d_population, MAX_POPULATION_SIZE * sizeof(int*));
    cudaMalloc((void**)&d_closest, MAX_POOL * sizeof(int*));

    // allocate memory for the data pointed to by the pointers on the device
    for (int i = 0; i < MAX_POPULATION_SIZE; i++) {
        cudaMalloc((void**)&(d_population[i]), CHROMOSOMES_SIZE * sizeof(int));
    }

    for (int i = 0; i < MAX_POOL; i++) {
        cudaMalloc((void**)&(d_closest[i]), CHROMOSOMES_SIZE * sizeof(int));
    }

    // copy the data from the host to the device
    cudaMemcpy(d_original, original, CHROMOSOMES_SIZE * sizeof(int), cudaMemcpyHostToDevice);

    for (int i = 0; i < MAX_POPULATION_SIZE; i++) {
        cudaMemcpy(d_population[i], population[i], CHROMOSOMES_SIZE * sizeof(int), cudaMemcpyHostToDevice);
    }

    for (int i = 0; i < MAX_POOL; i++) {
        cudaMemcpy(d_closest[i], closest[i], CHROMOSOMES_SIZE * sizeof(int), cudaMemcpyHostToDevice);
    }

    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::time_point_cast<std::chrono::milliseconds>(now);
    auto start = ms.time_since_epoch().count();

    while (!check(original, population) && iterations < MAX_ITERATIONS)
    {
        iterations++;
        printf("Iteration: %d\n", iterations);

        for (int i = COMBINATIONAL_CROSSING_SIZE; i < MAX_POPULATION_SIZE; i++) {
            cudaMemcpy(d_population[i], population[i], CHROMOSOMES_SIZE * sizeof(int), cudaMemcpyHostToDevice);
        }

        get_distances_gpu << <MAX_POPULATION_SIZE, 256 >> > (d_population, d_original, d_distances);
        cudaMemcpy(distances, d_distances, MAX_POPULATION_SIZE * sizeof(int), cudaMemcpyHostToDevice);

        //CPU Implementation
        // get_distances(population, original, distances, sorted);

        get_closest_distances(population, closest, distances, sorted);

        combinational_crossing_gpu << <MAX_POOL, MAX_POOL >> > (d_population, d_closest);
        for (int i = 0; i < COMBINATIONAL_CROSSING_SIZE; i++) {
            cudaMemcpy(population[i], d_population[i], CHROMOSOMES_SIZE * sizeof(int), cudaMemcpyDeviceToHost);
        }

        //CPU Implementation
        // combinational_crossing(population, closest);
        mutate(population, closest, COMBINATIONAL_CROSSING_SIZE);
    }

    now = std::chrono::system_clock::now();
    ms = std::chrono::time_point_cast<std::chrono::milliseconds>(now);
    auto end = ms.time_since_epoch().count();
    std::printf("Time taken: %2.4f s\n", (end - start) / 1000.0);

    delete distances;
    delete sorted;
    delete[] population;
    delete[] closest;

    return 0;
}