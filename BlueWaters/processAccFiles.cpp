#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <unordered_map>

inline unsigned decode(std::string const &name) {
	static std::unordered_map<std::string, unsigned> table = {{"1M", 1000000}, {"4M", 4000000}, {"8M", 8000000}};
	return table[name];
}

int main() {
	const std::string base_dir = "results/";
	const std::vector<std::string> types({"CPU", "CPU-SMP", "GPU-SMP", "GPU-SMP-Wang", "GPU-SMP-Simon", "GPU-SMP-Simon+Wang"});
	const std::vector<std::string> theta({"0.1", "0.2", "0.3", "0.4", "0.5", "0.7", "0.9"});
	std::unordered_map<std::string, std::string> config = {
	    {"CPU", "1"}, {"CPU-SMP", "30"}, {"GPU-SMP", "1"}, {"GPU-SMP-Wang", "1"}, {"GPU-SMP-Simon", "1"}, {"GPU-SMP-Simon+Wang", "1"}};

	for (auto const &type : types) {
		for (auto numparticles : {"1M"}) {
			auto N = decode(numparticles);
			std::vector<float> x(3U * N);
			const auto threads = config[type];
			for (auto t : theta) {
				for (auto b : {"128"}) {
					const std::string dir{base_dir + "/" + type + "/" + numparticles + "/" + threads + "/" + t + "/" + b + "/" + "acc/"};
					const std::string prefix{type + "+" + numparticles + "+" + threads + "+" + t + "+" + b};
					const std::string input_file{dir + prefix + ".acc"};

					std::cout << "Processing " << input_file << '\n';

					std::ifstream fin{input_file};
					if (!fin) {
						std::cerr << "Unable to open " << input_file << std::endl;
						return -1;
					}

					fin >> x[0]; // skip the header
					for (auto &v : x) {
						fin >> v;
					}

					std::ofstream fout{input_file + ".dat"};
					fout.write(reinterpret_cast<char *>(x.data()),
						   static_cast<std::streamsize>(x.size() * sizeof(decltype(x)::value_type)));

					std::ofstream hdr{input_file + ".dat.hdr"};
					hdr << 6 << '\n' << 2 << '\n' << N << ' ' << 3 << '\n';
				}
			}
		}
	}
}
