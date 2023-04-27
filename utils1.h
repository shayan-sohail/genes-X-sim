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
constexpr int MAX_ITERATIONS = 10000;


using Gene = struct Gene
{
    std::vector<int> chromosomes;

    Gene()
    {
        chromosomes.resize(CHROMOSOMES_SIZE);
    }
};

class Utils
{
public:
    static void get_euclidean_distances(std::vector<Gene>& population, Gene& original, std::vector<double>& dists)
    {
        std::fill(dists.begin(), dists.end(), 0);
        for (int i = 0; i < MAX_POPULATION_SIZE; i++)
        {
            for (int j = 0; j < CHROMOSOMES_SIZE; j++)
            {
                dists[i] += pow(original.chromosomes[j] - population[i].chromosomes[j], 2);
            }
            dists[i] = sqrt(dists[i]);
        }
    }

    static void get_closest_matches(std::vector<Gene>& population, std::vector<Gene>& closest, std::vector<double>& dists, Gene& original)
    {
        static int iteration = 1;
        std::vector<double> sorted_dists = dists;
        sort(sorted_dists.begin(), sorted_dists.end());
        if (iteration % 100 == 0) printf("Sorted = %2.4f\tSum = %2.4f\n", sorted_dists[0], std::accumulate(sorted_dists.begin(), sorted_dists.end(), 0.0));
        for (int i = 0; i < MAX_POOL; i++)
        {
            closest[i] = population[std::distance(dists.begin(), std::find(dists.begin(), dists.end(), sorted_dists[i]))];
        }

        iteration++;
    }

    static int combinational_crossing(std::vector<Gene>& population, std::vector<Gene>& closest)
    {
        auto inner_count = 0;

        for (int i = 0; i < MAX_POOL; i++)
        {
            for (int j = i + 1; j < MAX_POOL; j++)
            {
                for (int p = 0; p < 60; p++)
                {
                    population[inner_count + 0] = closest[i];
                    population[inner_count + 1] = closest[j];
                    population[inner_count + 2] = closest[i];
                    population[inner_count + 3] = closest[j];

                    population[inner_count + 0].chromosomes[3 * p + 0] = closest[j].chromosomes[3 * p + 3];
                    population[inner_count + 0].chromosomes[3 * p + 1] = closest[j].chromosomes[3 * p + 4];
                    population[inner_count + 0].chromosomes[3 * p + 2] = closest[j].chromosomes[3 * p + 5];

                    population[inner_count + 1].chromosomes[3 * p + 0] = closest[i].chromosomes[3 * p + 3];
                    population[inner_count + 1].chromosomes[3 * p + 1] = closest[i].chromosomes[3 * p + 4];
                    population[inner_count + 1].chromosomes[3 * p + 2] = closest[i].chromosomes[3 * p + 5];

                    population[inner_count + 2].chromosomes[3 * p + 3] = closest[j].chromosomes[3 * p + 0];
                    population[inner_count + 2].chromosomes[3 * p + 4] = closest[j].chromosomes[3 * p + 1];
                    population[inner_count + 2].chromosomes[3 * p + 5] = closest[j].chromosomes[3 * p + 2];

                    population[inner_count + 3].chromosomes[3 * p + 3] = closest[i].chromosomes[3 * p + 0];
                    population[inner_count + 3].chromosomes[3 * p + 4] = closest[i].chromosomes[3 * p + 1];
                    population[inner_count + 3].chromosomes[3 * p + 5] = closest[i].chromosomes[3 * p + 2];

                    inner_count += 4;
                }
            }
        }
        return inner_count;
    }

    static void mutate(std::vector<Gene>& population, std::vector<Gene>& closest, int offset)
    {
        auto x = offset;
        srand(time(NULL));
        for (int i = 0; i < MAX_POOL; i++)
        {
            for (int j = 0; j < CHROMOSOMES_SIZE; j++)
            {
                population[x] = closest[i];
                population[x].chromosomes[j] = rand() % 55;
                x++;
            }
        }
    }

    static bool check(Gene original, std::vector<Gene>& population)
    {
        for (int i = 0; i < MAX_POPULATION_SIZE; i++)
        {
            if (population[i].chromosomes == original.chromosomes)
            {
                printf("Match Found at population %d\n", i); return true;
            }
        }
        return false;
    }
};
