#pragma once
#include <vector>
#include <cmath>
#include <random>
#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <numeric>

constexpr int POPULATION_SIZE = 30;
constexpr int MAX_POPULATION_SIZE = 109890;
constexpr int CHROMOSOMES_SIZE = 183;
constexpr int MAX_POOL = 30;
constexpr int MAX_ITERATIONS = 100;

class Utils
{
public:
    static void get_distances(int**& population, int* original, double*& distances, double*& sorted)
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

    static void get_closest_distances(int**& population, int**& closest, double*& distances, double*& sorted)
    {
        static int iteration = 1;
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

    static int combinational_crossing(int**& population, int**& closest)
    {
        auto inner_count = 0;

        for (int i = 0; i < MAX_POOL; i++)
        {
            auto N = 0;
            for (int j = i + 1; j < MAX_POOL; j++)
            {
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
                // if (i < 5) printf("i: %d\tj: %d\tcount: %d\n", i, j, inner_count);
            }
        }
        printf("Inner Count is %d\n", inner_count);
        exit(1);
        return inner_count;
    }

    static void mutate(int**& population, int**& closest, int offset)
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

    static bool check(int* original, int**& population)
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
};
