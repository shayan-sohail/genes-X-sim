#include <iostream>
#include <chrono>
#include "utils3.h"

void initialize(int**& population, int* original, double*& dists, double*& sorted, int**& closest)
{
    srand(time(NULL));
    int x = 0;
    for (int i = 0; i < POPULATION_SIZE; i++)
    {
        for (int j = 0; j < CHROMOSOMES_SIZE; j++)
        {
            population[i][j] = x % 54;
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
    printf("ISortedX = %2.4f\tSum = %2.4f\n", sorted[0], std::accumulate(sorted, sorted + POPULATION_SIZE, 0.0));

}

int main()
{
    srand(time(NULL));
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
    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::time_point_cast<std::chrono::milliseconds>(now);
    auto start = ms.time_since_epoch().count();

    Utils::mutate(population, closest, Utils::combinational_crossing(population, closest));
    while (!Utils::check(original, population) && iterations < MAX_ITERATIONS)
    {
        iterations++;
        if (iterations % 10 == 0) printf("Iteration: %d\n", iterations);
        Utils::get_distances(population, original, distances, sorted);
        Utils::get_closest_distances(population, closest, distances, sorted);
        Utils::mutate(population, closest, Utils::combinational_crossing(population, closest));
    }

    if (iterations == MAX_ITERATIONS) printf("Max Iterations Reached\n");
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