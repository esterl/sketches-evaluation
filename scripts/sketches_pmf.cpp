// Simple tests
// g++ -std=gnu++11 -o SketchesPMF sketches_pmf.cpp `pkg-config --cflags --libs gsl` 
#include <iostream>
#include <unordered_map>
#include <gsl/gsl_randist.h>
#include <gsl/gsl_sf_gamma.h>
#include <math.h>
#include <fstream>
#include <limits>
#include <vector>
#include <iterator>
#include <chrono>
#include <ctime>
#include <algorithm>
#include <string>
#include <tclap/CmdLine.h>

typedef std::unordered_map<double, double> PMF;

/****************************** utils *****************************************/
void save_pmf(std::string filename, PMF& pmf, std::string sketch, 
                unsigned packets, unsigned columns, unsigned rows, 
                std::string avgFunction){
    std::ofstream cvs_file(filename);
    typedef std::numeric_limits<double> dbl;
    cvs_file << "EstimatedPackets,Probability,SketchType,SketchColumns," << 
        "SketchRows,SketchedPackets,AverageFunction" << std::endl;
    double total = 0.0;
    for (auto it = pmf.begin(); it != pmf.end(); it++){
        cvs_file << it->first << "," <<  it->second << "," << sketch << "," << 
            columns << "," << rows << "," << packets << "," << avgFunction <<
            std::endl;
        total += it->second;
    }
    std::cout << total << std::endl;
}

PMF sum_pmf(PMF& pmf1, PMF& pmf2){
    PMF result(pmf1.size()*pmf2.size());
    for ( auto it1 = pmf1.begin(); it1 != pmf1.end(); it1++ ) {
        for ( auto it2 = pmf2.begin(); it2 != pmf2.end(); it2++ ) {
            double support = it1->first + it2->first;
            double probability = it1->second * it2->second;
            result[support] += probability;
        }
    }
    return result;
}

void print_pmf(PMF& pmf){
    for (auto it = pmf.begin(); it != pmf.end(); it++){
        std::cout << it->first << ",\t" <<  it->second << std::endl;
    }
}

inline void print_time(){
    std::chrono::time_point<std::chrono::system_clock> time_now;
    time_now = std::chrono::system_clock::now();
    std::time_t time_t_now = std::chrono::system_clock::to_time_t(time_now);
    std::cout << std::ctime(&time_t_now);
}

std::string get_filename(const std::string basename, const std::string type, 
                            unsigned packets, unsigned columns, unsigned rows, 
                            std::string function) {
    return basename + "_" + type + "_" + std::to_string(packets) + "_" + 
        std::to_string(columns) + "_" + std::to_string(rows) + "_" + function +
        ".csv";
}

double mean(double* values, unsigned int n) {
    double sum = 0;
    for (unsigned int i = 0; i < n; i++)
        sum += values[i];
    return sum / (double) n;
}

double median(double* values, unsigned int n) {
    if (n == 1)
        return values[0];

    if (n == 2)
        return (values[0] + values[1]) / 2.;

    double *aux = new double[n];
    for (unsigned int i = 0; i < n; i++)
        aux[i] = values[i];

    std::sort(aux, aux + n);

    double res;
    if (n % 2 == 0)
        res = (aux[n / 2 - 1] + aux[n / 2]) / 2.;
    else
        res = aux[n / 2];

    delete[] aux;
    return res;
}
/******************************* Basic PMFs ***********************************/
PMF get_binomial_pmf (unsigned packets, double p = 0.5){
    PMF result;
    for ( unsigned i = 0; i <= packets; i++){
        double probability = gsl_ran_binomial_pdf (i, p, packets);
        result[i] = probability;
    }
    return result;
}

PMF get_pm1_pmf(unsigned packets){
    PMF result, aux;
    aux = get_binomial_pmf(packets);
    for ( unsigned i = 0; i <=packets; i++ ) {
        double support = 2.*i - packets;
        result[support]+= aux[i];
    }
    return result;
}

/************************** PMF of the median *********************************/
double probability_median(int pivot1, int pivot2, unsigned n, unsigned values, 
                            double* p_less, double* p_greater, double* p_pivot1, 
                            double* p_pivot2){
    //std::cout << " pivots: " << pivot1 << " " << pivot2 << std::endl;
    double probability = 0.;
    // i position pivot1, j position pivot2
    int max_i = pivot1 > 0 ? (n-1)/2 : 0;
    int min_j = pivot2 < values-1 ? n/2 : n - 1;
    double choose_i = 1;
    double choose_p = 1;
    if ( pivot1 != pivot2 ) {
        for ( int i = 0; i < n/2; i++)
            choose_p = choose_p * (n - i) / (n/2 - i);
    }
    double choose_p0 = choose_p;
    for ( int i = 0; i <= max_i; i++ ) {
        int n_small = i;
        double choose_j = 1;
        for ( int j = n-1; j >= min_j; j-- ) {
            int n_big = n - j - 1;
            // Number of smaller values:
            double partial = 1.;
            if ( n_small > 0 ) {
                partial *= choose_i * p_less[(n_small-1)*values + pivot1 -1];
            }
            // Number of bigger values:
            if ( n_big > 0 ) {
                partial *= choose_j * p_greater[(n_big-1)*values + pivot2 + 1];
            }
            // Probability of the pivots:
            partial *= p_pivot1[(n-1)/2-i];
            if ( j - max_i > 0 ){
                partial *= p_pivot2[j - (n-1)/2 - 1];
            }
            if ( pivot1 != pivot2 ) {
                partial *= choose_p;
                choose_p = choose_p / (n - n_small - n_big) * (n/2 - n_big);
            }
            probability += partial;
            choose_j = choose_j * (n-n_small-n_big) / (n_big + 1);
        }
        choose_i = choose_i * (n-i)/(i+1);
        if ( n != n_small) {
            choose_p = choose_p0 / (n - n_small) * (n/2 - n_small);
            choose_p0 = choose_p;
        }
    }
    return probability;
}

double* probability_less(int estimations, int values, PMF& pmf, 
                            std::vector<double>& support) {
    // Fill a matrix of the probability that the max value of "n+1" estimations
    // is v=support[i]
    // P(max == v, n) = P(max == v, n-1) * P(e_n <= v) + 
    //                      P(max < v, n-1) * P(e_n==v)
    double* p_max = new double[estimations*values];
    if ( values == 0 || estimations == 0 ) return p_max;
    // First row is the PMF
    for ( int i = 0; i < values; i++){
        p_max[i] = pmf[support[i]];
    }
    for ( int n = 1; n < estimations; n++) {
        double latter_smaller = 0.; // P(e_n <= v)
        double former_smaller = 0;  // P(max < v, n-1)
        for ( int i = 0; i < values; i++) {
            latter_smaller += pmf[support[i]];
            p_max[n*values + i] = p_max[(n-1)*values + i] * latter_smaller + 
                                    former_smaller * pmf[support[i]];
            former_smaller += p_max[(n-1)*values + i];
        }
    }
    
    // Fill a matrix with the probability of having "n+1+ estimations with value
    // less or equal to v=support[i]
    // P ( estimations <= v, n) = sum(P ( max <= v, n))
    double * p_less = new double[estimations*values];
    for ( int n = 0; n < estimations; n++) {
        p_less[n*values] = p_max[n*values];
        for ( int i = 1; i < values; i++) {
            p_less[n*values+i] = p_less[n*values+i-1] + p_max[n*values+i];
        }
    }
    delete [] p_max;
    return p_less;
}

double* probability_greater(int estimations, int values, PMF& pmf, 
                            std::vector<double>& support) {
    // Fill a matrix of the probability that the min value of "n+1" estimations
    // is v=support[i]
    // P(min == v, n) = P(min == v, n-1) * P(e_n >= v) + 
    //                      P(min > v, n-1) * P(e_n==v)
    double* p_min = new double[estimations*values];
    if ( values == 0 || estimations == 0 ) return p_min;
    // First row is the PMF
    for ( int i = 0; i < values; i++){
        p_min[i] = pmf[support[i]];
    }
    for ( int n = 1; n < estimations; n++) {
        double latter_bigger = 0.; // P(e_n <= v)
        double former_bigger = 0;  // P(max < v, n-1)
        for ( int i = values - 1; i >= 0; i--) {
            latter_bigger += pmf[support[i]];
            p_min[n*values + i] = p_min[(n-1)*values + i] * latter_bigger + 
                                    former_bigger * pmf[support[i]];
            former_bigger += p_min[(n-1)*values + i];
        }
    }
    
    // Fill a matrix with the probability of having "n+1+ estimations with value
    // greater or equal to v=support[i]
    // P ( estimations >= v, n) = sum(P ( min >= v, n))
    double * p_greater = new double[estimations*values];
    for ( int n = 0; n < estimations; n++) {
        p_greater[(n+1)*values-1] = p_min[(n+1)*values-1];
        for ( int i = values-2; i >= 0; i--) {
            p_greater[n*values+i] = p_greater[n*values+i+1] + p_min[n*values+i];
        }
    }
    delete [] p_min;
    return p_greater;
}

double* probability_pivot(double value, int max_estimations, PMF &pmf){
    double *p_pivot = new double[max_estimations];
    double probability = pmf[value];
    p_pivot[0] = probability;
    for ( int i = 1 ; i < max_estimations; i++) {
        p_pivot[i] = p_pivot[i-1] * probability;
    }
    return p_pivot;
}

PMF median_pmf(PMF& pmf, unsigned n){
    if ( n <= 1 ) return pmf;
    PMF result;
    
    // Get dimensions: 
    unsigned estimations = (n-1)/2;
    unsigned values = pmf.size();
    
    // Get the possible error values and order them:
    std::vector<double> support;
    for ( auto it = pmf.begin(); it != pmf.end(); it++) {
        support.push_back(it->first);
    }
    std::sort(support.begin(), support.end());
    
    double *p_less = probability_less(estimations, values, pmf, support);
    double *p_greater = probability_greater(estimations, values, pmf, support);
    
    // Now construct the pmf of the median, by checking all the possibilities of
    // which value can the pivot have.
    // If n odd, there is one pivot:
    if ( n % 2 == 1 ) {
        for ( int pivot = 0; pivot < values; pivot++) {
            double *p_pivot = probability_pivot(support[pivot], n, pmf);
            // TODO till half should be enough.
            result[support[pivot]] = probability_median(pivot, pivot, n, values, 
                                        p_less, p_greater, p_pivot, p_pivot);
            delete [] p_pivot;
        }
    } else {
        for ( int pivot1 = 0; pivot1 < values; pivot1++){
            double *p_pivot1 = probability_pivot(support[pivot1], n, pmf);
            for ( int pivot2 = pivot1; pivot2 < values; pivot2++) {
                double *p_pivot2 = probability_pivot(support[pivot2], n, pmf);
                result[(support[pivot1]+support[pivot2])/2] += 
                    probability_median(pivot1, pivot2, n, values, p_less, 
                                        p_greater, p_pivot1, p_pivot2);
                delete [] p_pivot2;
            }
            delete [] p_pivot1;
        }
    }
    
    delete [] p_less;
    delete [] p_greater;
    return result;
}

/***************************** PMF of the mean ********************************/
PMF mean_pmf(PMF& pmf, unsigned n){
    PMF result;
    PMF aux = PMF(pmf);
    unsigned i;
    for (i = 1; 2*i <= n; i=i*2){
        aux = sum_pmf(aux, aux);
    }
    // Last missing bits:
    for (; i<n; i++){
        aux = sum_pmf(aux, pmf);
    }
    
    for (auto it = aux.begin(); it != aux.end(); it++ ){
        double support = it->first/n;
        double probability = it->second;
        result[support] += probability;
    }
    return result;
}

/************************** PMF of the Sketches *******************************/
PMF get_AGMS_pmf(unsigned packets, unsigned columns){
    PMF result = PMF(packets*packets*columns/4);;
    PMF binomial_pmf = get_binomial_pmf(packets);
    PMF base_pmf = PMF(packets*packets*columns/4);;
    for ( unsigned i = 0; i <=packets; i++ ) {
        double support = pow(2.*i - packets, 2);
        base_pmf[support]+= binomial_pmf[i];
    }
    PMF aux = PMF(base_pmf);
    for (unsigned i = 1; i < columns; i++){
        aux = sum_pmf(aux, base_pmf);
    }
    for (auto it = aux.begin(); it != aux.end(); it++ ){
        double support = it->first/columns;
        double probability = it->second;
        result[support] += probability;
    }
    return result;
}

PMF get_FastCount_pmf(unsigned packets, unsigned columns){
    PMF result, *byRemaining, *newRemaining, *aux ;
    byRemaining = new PMF[packets+1];
    newRemaining = new PMF[packets+1];
    
    // Fill first byRemaining:
    byRemaining[packets][0.0] = 1;
    for (unsigned i = 0; i < columns - 1; i++) {
        for (unsigned j = 0; j<packets+1; j++) {
            if ( byRemaining[j].size() > 0 ) {
                PMF binomial_pmf = get_binomial_pmf(j, 1./(columns-i));
                // Sum byRemaining[j] with binomial_pmf, save result in newRemaining[]
                for (auto it1 = byRemaining[j].begin(); it1 != byRemaining[j].end(); it1++) {
                    for (auto it2 = binomial_pmf.begin(); it2 != binomial_pmf.end(); it2++) {
                        double alpha = it1->first + pow(it2->first, 2);
                        unsigned remaining = j - it2->first;
                        double probability = it2->second *it1->second;
                        newRemaining[remaining][alpha] += probability;
                    }
                }
            }
        }
        // swap byRemaining/newRemaining
        aux = byRemaining; byRemaining = newRemaining; newRemaining = aux;
        // clear newRemaining;
        for (unsigned j = 0; j<packets+1; j++) {
            newRemaining[j].clear();
        }
    }
    
    // Sum byRemaining -> "merge" by column -> compute prediction
    for (unsigned j = 0; j<packets+1; j++) {
        for (auto it = byRemaining[j].begin() ; it != byRemaining[j].end(); it++) {
            double alpha = it->first + j*j;
            double prediction = double(columns)/(columns -1) * alpha - 
                                packets * (double(packets)/(columns-1));
            result[prediction] += it->second;
        }
    }
    delete [] byRemaining;
    delete [] newRemaining;
    return result;
}

PMF get_FAGMS_pmf(unsigned packets, unsigned columns){
    PMF result, *byRemaining, *newRemaining, *aux ;
    byRemaining = new PMF[packets+1];
    newRemaining = new PMF[packets+1];
    
    // Fill first byRemaining:
    byRemaining[packets][0.0] = 1;
    for (unsigned i = 0; i < columns - 1; i++) {
        for (unsigned j = 0; j<packets+1; j++) {
            if ( byRemaining[j].size() > 0 ) {
                PMF binomial_pmf = get_binomial_pmf(j, 1./(columns-i));
                // Sum byRemaining[j] with binomial_pmf, save result in newRemaining[]
                for (auto it1 = byRemaining[j].begin(); it1 != byRemaining[j].end(); it1++) {
                    for (auto it2 = binomial_pmf.begin(); it2 != binomial_pmf.end(); it2++) {
                        // Compute number of +1s :
                        PMF pm1_pmf = get_pm1_pmf(it2->first);
                        for (auto it3 = pm1_pmf.begin(); it3 != pm1_pmf.end(); it3++){
                            double alpha = it1->first + pow(it3->first, 2);
                            unsigned remaining = j - it2->first;
                            double probability = it2->second *it1->second * it3->second;
                            newRemaining[remaining][alpha] += probability;
                        }
                    }
                }
            }
        }
        // swap byRemaining/newRemaining
        aux = byRemaining; byRemaining = newRemaining; newRemaining = aux;
        // clear newRemaining;
        for (unsigned j = 0; j<packets+1; j++) {
            newRemaining[j].clear();
        }
    }
    // Last column
    for (unsigned j = 0; j<packets+1; j++) {
        if ( byRemaining[j].size() > 0 ) {
            // Distribution for the missing column
            PMF pm1_pmf = get_pm1_pmf(j);
            // Sum byRemaining[j] with binomial_pmf, save result in newRemaining[]
            for (auto it1 = byRemaining[j].begin(); it1 != byRemaining[j].end(); it1++) {
                for (auto it2 = pm1_pmf.begin(); it2 != pm1_pmf.end(); it2++) {
                    double alpha = it1->first + pow(it2->first,2);
                    double probability = it1->second * it2->second;
                    result [alpha] += probability;
                }
            }
        }
    }
    delete [] byRemaining;
    delete [] newRemaining;
    return result;
}

/********************** PMF obtained by MC simulation **************************/
PMF simulate_AGMS(unsigned packets, unsigned columns, unsigned rows, 
                std::string avgFunction, unsigned samples){
    PMF result;
    double *row_values = new double[rows];
    // Setup of the random generator
    gsl_rng *rng;
    rng = gsl_rng_alloc(gsl_rng_mt19937); //Mersenne twister MT-19937 as PRNG
    std::random_device rd;
    std::uniform_int_distribution<int> seed;
    gsl_rng_set(rng, seed(rd));
    for ( unsigned i = 0; i<samples; i++ ){
        // Make 1 prediction: columns*rows random binomial
        for ( unsigned row = 0; row < rows; row++) {
            row_values[row] = 0.0;
            for ( unsigned column = 0; column < columns; column++){
                int pm1 = gsl_ran_binomial(rng, 0.5, packets);
                row_values[row] += pow(2*pm1-(int)packets, 2);
            }
            row_values[row] = row_values[row]/columns;
        }
        if ( avgFunction == std::string("mean") ) {
            result[mean(row_values, rows)] += 1./samples;
        } else {
            result[median(row_values, rows)] += 1./samples;
        }
    }
    delete [] row_values;
    gsl_rng_free(rng);
    return result;
}

PMF simulate_FastCount(unsigned packets, unsigned columns, unsigned rows, 
                std::string avgFunction, unsigned samples) {
    PMF result;
    double *row_values = new double[rows];
    unsigned *col_values = new unsigned[columns];
    double *probability = new double[columns]; // Each column has the same probability
    for ( unsigned i = 0; i<columns; i++ ) {
        probability[i] = 1./columns;
    }
    
    // Setup of the random generator
    gsl_rng *rng;
    rng = gsl_rng_alloc(gsl_rng_mt19937); //Mersenne twister MT-19937 as PRNG
    std::random_device rd;
    std::uniform_int_distribution<int> seed;
    gsl_rng_set(rng, seed(rd));
    
    for ( unsigned i = 0; i<samples; i++ ){
        // Make 1 prediction: columns*rows random binomial
        for ( unsigned row = 0; row < rows; row++) {
            gsl_ran_multinomial(rng, columns, packets, probability, col_values);
            double value = 0.0;
            double value2 = 0.0;
            for ( unsigned column = 0; column < columns; column++){
                value += col_values[column];
                value2 += pow(col_values[column], 2);
            }
            row_values[row] = 1./(columns-1) * (columns*value2 - pow(value,2));
        }
        if ( avgFunction == std::string("mean") ) {
            result[mean(row_values, rows)] += 1./samples;
        } else {
            result[median(row_values, rows)] += 1./samples;
        }
    }
    delete [] row_values;
    delete [] col_values;
    delete [] probability;
    gsl_rng_free(rng);
    return result;
}

PMF simulate_FAGMS(unsigned packets, unsigned columns, unsigned rows, 
                std::string avgFunction, unsigned samples) {
    PMF result;
    double *row_values = new double[rows];
    unsigned *col_values = new unsigned[columns];
    double *probability = new double[columns]; // Each column has the same probability
    for ( unsigned i = 0; i<columns; i++ ) {
        probability[i] = 1./columns;
    }
    
    // Setup of the random generator
    gsl_rng *rng;
    rng = gsl_rng_alloc(gsl_rng_mt19937); //Mersenne twister MT-19937 as PRNG
    std::random_device rd;
    std::uniform_int_distribution<int> seed;
    gsl_rng_set(rng, seed(rd));
    
    for ( unsigned i = 0; i<samples; i++ ){
        // Make 1 prediction: columns*rows random binomial
        for ( unsigned row = 0; row < rows; row++) {
            gsl_ran_multinomial(rng, columns, packets, probability, col_values);
            row_values[row] = 0.0;
            for ( unsigned column = 0; column < columns; column++){
                int pm1 = (int) gsl_ran_binomial(rng, 0.5, col_values[column]);
                row_values[row] += pow(2 * pm1 - (int) col_values[column],2);
            }
        }
        if ( avgFunction == std::string("mean") ) {
            result[mean(row_values, rows)] += 1./samples;
        } else {
            result[median(row_values, rows)] += 1./samples;
        }
    }
    delete [] row_values;
    delete [] col_values;
    delete [] probability;
    gsl_rng_free(rng);
    return result;
}


/********************************* Main ***************************************/
int main(int argc, char** argv) {
  try {
    // Parse arguments
    TCLAP::CmdLine cmd("PMF of a sketch with the given characteristics", ' ', 
                       "1.0");
    TCLAP::MultiArg<std::string> typeArg("t", "sketchType", "Sketch type", 
                                         false, "string", cmd);
    TCLAP::MultiArg<std::string> funcArg("a", "averageFunction", 
                                         "Average function", false, "string", 
                                         cmd);
    TCLAP::MultiArg<int> packetsArg("p", "packets", "Number of packets", true, 
                                    "int", cmd);
    TCLAP::MultiArg<int> columnsArg("c", "columns", "Sketch columns", true, 
                                    "int", cmd);
    TCLAP::MultiArg<int> rowsArg("r", "rows", "Sketch rows", false, "int", cmd);
    TCLAP::SwitchArg montecarloFlag("m", "montecarlo", "Simulate the PMF", cmd, 
                                    false);
    TCLAP::ValueArg<int> samplesArg("s", "samples", 
                                    "Number of Montecarlo samples", false, 
                                    100000, "int", cmd);
    TCLAP::UnlabeledValueArg<std::string> basename("basename", 
      "Basename for the .csv files", true, "PMF", "string", cmd);
    cmd.parse(argc, argv);

    std::vector<std::string> types = typeArg.getValue();
    if ( types.empty() ) {
      types = std::vector<std::string>({"AGMS", "FAGMS", "FastCount"});
    }
    std::vector<int> packets = packetsArg.getValue();
    std::vector<int> columns = columnsArg.getValue();
    std::vector<int> rows = rowsArg.getValue();
    std::vector<std::string> avgFuncs = funcArg.getValue();
    if (rows.empty()) {
      rows.push_back(1);
      if ( avgFuncs.empty()) {
        avgFuncs.push_back("median");
      }
    } else {
      if (avgFuncs.empty()) {
        avgFuncs = std::vector<std::string>({"mean", "median"});
      }
    }

    // Compute PMF for each configuration
    for (auto &type : types) {
      for (auto &pkts : packets) {
        for (auto &ncol : columns) {
        // MONTECARLO
          if (montecarloFlag.getValue()){
            int samples = samplesArg.getValue();
            for (auto &nrow : rows) {
              for (auto &func : avgFuncs) {
                PMF result;
                if ( type == std::string("AGMS")) {
                  result = simulate_AGMS(pkts,  ncol, nrow, func, samples);
                } else if (type == std::string("FAGMS")) {
                  result = simulate_FAGMS(pkts,  ncol, nrow, func, samples);
                } else {
                  result = simulate_FastCount(pkts,  ncol, nrow, func, samples);
                }
                std::string name = get_filename(basename.getValue(), type, pkts,
                                                ncol, nrow, func);
                save_pmf(name, result, type, pkts, ncol, nrow, func);
              }
            }
          // Computation
          } else {
            PMF aux, result;
            if (type == std::string("AGMS")) {
              aux = get_AGMS_pmf(pkts, ncol);
            } else if (type == std::string("FAGMS")) {
              aux = get_FAGMS_pmf(pkts, ncol);
            } else {
              aux = get_FastCount_pmf(pkts, ncol);
            }
            for (auto &nrow : rows ) {
              for (auto &func: avgFuncs) {
                if ( func == std::string("median")){
                  result = median_pmf(aux, nrow);
                } else {
                  result = mean_pmf(aux, nrow);
                }
                std::string name = get_filename(basename.getValue(), type, pkts,
                                                ncol, nrow, func);
                save_pmf(name, result, type, pkts, ncol, nrow, func);
              }
            }
          }
        }
      }
    }
  } catch (TCLAP::ArgException &e) {
    std::cerr << "error: " << e.error() << " for arg " << e.argId() << 
      std::endl;
  }
}

