#include "../hd/class.hpp"

using namespace std;

float frand_a_b(float a, float b){
    return ( rand()/(float)RAND_MAX ) * (b-a) + a;
}

Net::Net(int *size_layers, int nb_layers, int nb_input){

	m_nb_layers = nb_layers;
	m_nb_input = nb_input;

	m_size_layers = new int[nb_layers];

	for(int i = 0; i< nb_layers; i++){
		m_size_layers[i] = size_layers[i];
	}

	//max_size for layers
	int max = 0;
	for(int i = 0; i<nb_layers; i++){
		if(size_layers[i] > max)
			max = size_layers[i];
	}
	m_max_lay = max;

	//bias - alloc
	m_bias = new float*[nb_layers];
	for(int i = 0; i<nb_layers; i++){
		m_bias[i] = new float[size_layers[i]];
	}
	//bias - init
	for(int i = 0; i<nb_layers; i++){
		for(int j = 0; j<size_layers[i]; j++){
			m_bias[i][j] = frand_a_b(0.f, 1.f);
		}
	}

	//weight - alloc/init
	m_weight = new float**[nb_layers];
	for(int i = 0; i<nb_layers; i++){
		m_weight[i] = new float*[size_layers[i]];
	}
	for(int i = 0; i<nb_layers; i++){
		for(int j = 0; j<size_layers[i]; j++){
			if(i == 0){ // particular case : first layer
				m_weight[i][j] = new float[nb_input];
				for(int k = 0; k<nb_input; k++){ // init
					m_weight[i][j][k] = frand_a_b(0.f, 1.f);
				}
			}
			else{ // other layers
				m_weight[i][j] = new float[size_layers[i-1]];
				for(int k = 0; k<size_layers[i-1]; k++){ // init
					m_weight[i][j][k] = frand_a_b(0.f, 1.f);
				}
			}
		}
	}

	//grad - alloc/init
	m_grad = new float*[nb_layers];
	for(int i = 0; i<nb_layers; i++){
		m_grad[i] = new float[size_layers[i]];
	}
	//grad - init
	for(int i = 0; i<nb_layers; i++){
		for(int j = 0; j<size_layers[i]; j++){
			m_grad[i][j] = 0;
		}
	}

	//delta - alloc/init
	m_delta = new float**[nb_layers];
	for(int i = 0; i<nb_layers; i++){
		m_delta[i] = new float*[size_layers[i]];
	}
	for(int i = 0; i<nb_layers; i++){
		for(int j = 0; j<size_layers[i]; j++){
			if(i == 0){ // particular case : first layer
				m_delta[i][j] = new float[nb_input];
				for(int k = 0; k<nb_input; k++){ // init
					m_delta[i][j][k] = 0;
				}
			}
			else{ // other layers
				m_delta[i][j] = new float[size_layers[i-1]];
				for(int k = 0; k<size_layers[i-1]; k++){ // init
					m_delta[i][j][k] = 0;
				}
			}
		}
	}
}

void Net::learning(float* input, float *expect){

	float* output = comput(input);
	float error = 0;
	float** transition = new float*[m_nb_layers];
	for(int i = 0; i<m_nb_layers; i++){
		transition[i] = new float[m_max_lay];
		for(int j = 0; j<m_max_lay; j++){
			transition[i][j] = 0;
		}
	}

	//computation with memory

	for(int i = 0; i<m_nb_layers; i++){ // for each layer
		for(int j = 0; j<m_size_layers[i]; j++){ // for each neuron
			//calcul layers
			if(i == 0){
				for(int k = 0; k<m_nb_input; k++){ // sum
					transition[0][j] += input[k] * m_weight[i][j][k];
				}
				transition[0][j] += m_bias[i][j];//bias
				transition[0][j] = sigmo(transition[0][j]);
			}
			else{
				for(int k = 0; k<m_size_layers[i-1]; k++){ // sum
					transition[i][j] += transition[i-1][k] * m_weight[i][j][k];
				}
				transition[i][j] += m_bias[i][j];//bias
				transition[i][j] = sigmo(transition[i][j]);
			}
		}
	}

	//error computation


	error = comput_error(transition[m_nb_layers-1], expect);

	cout << "Error : " << error << endl;

	//backprop

	float *y;

	for(int i = m_nb_layers-1; i>=0; i--){ // for each layer
		for(int j = 0; j<m_size_layers[i]; j++){ // for each neuron

			y = transition[i];

			//m_grad / m_delta
			if(i == m_nb_layers-1){ // output neuron

				m_grad[i][j] = - (expect[j]-y[j]) * y[j] * (1-y[j]);
				for(int k= 0; k<m_size_layers[i-1]; k++){
					m_delta[i][j][k] = m_grad[i][j] * transition[i-1][k];
				}
				/*cout << "[Debug couche " << i << "] ";
				for(int k = 0; k < m_size_layers[i]; k++){
					cout << "grad " << k << " : " << m_grad[i][k] << " ";
					for(int l= 0; l<m_size_layers[i-1]; l++)
						cout << "delta " << k << " poids " << l << " : " << m_delta[i][k][l] << " ";
				}
				cout << endl;*/
			}

			else if(i  == 0){ // input neuron
				m_grad[i][j] = 0;
				for(int k= 0; k<m_size_layers[i+1]; k++){
					m_grad[i][j] += m_grad[i+1][k] * m_weight[i+1][k][j];
				}
				m_grad[i][j] *= y[j] * (1-y[j]);
				for(int k= 0; k<m_nb_input; k++){
					m_delta[i][j][k] = m_grad[i][j] * input[k];
				}
			}

			else{ // others
				m_grad[i][j] = 0;
				for(int k= 0; k<m_size_layers[i+1]; k++){
					m_grad[i][j] += m_grad[i+1][k] * m_weight[i+1][k][j];
				}
				m_grad[i][j] *= y[j] * (1-y[j]);
				for(int k= 0; k<m_size_layers[i-1]; k++){
					m_delta[i][j][k] = m_grad[i][j] * transition[i-1][k];
				}
			}

		}


	}

	//backprop apply

	for(int i = m_nb_layers-1; i>=0; i--){ // for each layer
		for(int j = 0; j<m_size_layers[i]; j++){ // for each neuron
		if(i == 0){
				for(int k = 0; k<m_nb_input; k++){ // sum
					m_weight[i][j][k] += -learning_rate * m_delta[i][j][k];
				}
			}
			else{
				for(int k = 0; k<m_size_layers[i-1]; k++){ // sum
					m_weight[i][j][k] += -learning_rate * m_delta[i][j][k];
				}
			}
		}
	}

}

float Net::comput_error(float* out, float* expect){

	float error = 0;

	for(int i = 0; i<m_size_layers[m_nb_layers-1]; i++){
		error += 0.5*(out[i] - expect[i])*(out[i] - expect[i]);
	}
	return error;
}

float* Net::comput(float* input){

	float* transition = new float[m_max_lay];
	float* transition_old = new float[m_max_lay];

	for(int i = 0; i<m_nb_layers; i++){ // for each layer
		for(int j = 0; j<m_size_layers[i]; j++){ // for each neuron
			transition[j] = 0;
			//calcul layers
			if(i == 0){
				for(int k = 0; k<m_nb_input; k++){ // sum
					transition[j] += input[k] * m_weight[i][j][k];
				}
				transition[j] += m_bias[i][j];//bias
				transition[j] = sigmo(transition[j]);
			}
			else{
				for(int k = 0; k<m_size_layers[i-1]; k++){ // sum
					transition[j] += transition_old[k] * m_weight[i][j][k];
				}
				transition[j] += m_bias[i][j];//bias
				transition[j] = sigmo(transition[j]);
			}
		}
		//switch transistion
		for(int k = 0; k<m_size_layers[i]; k++){
				transition_old[k] = transition[k];
		}
	}
	return transition;

}

float Net::sigmo(float val){
    return 1/(1+exp(-val));
}
