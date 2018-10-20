# Here goes the main programme

require './gene_class.rb'
require './seedstock_class.rb'
require './cross_class.rb'

if (ARGV.length == 4)
	list_genes = create_genes(ARGV[0])
	list_seedstock = create_seedstock(list_genes, ARGV[1])
	list_crosses = create_cross(list_seedstock, ARGV[2])
else
	puts "There are input files missing."
	puts "You should introduce gene_information.tsv, seed_stock_data.tsv and cross_data.tsv and the new file you want to create (in that order)."
	exit
end

out_file = File.open(ARGV[3], "w")
out_file.puts("Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining")
list_seedstock.each_value do |seed|
	seed.planting_seeds(7)
	out_file.puts("#{seed.seed_stock}\t#{seed.mutant_geneID.ID}\t#{Time.now.strftime("%d/%m/%Y")}\t#{seed.storage}\t#{seed.grams_remaining}")
end


puts list_crosses["A334"].parent2.mutant_geneID.name
