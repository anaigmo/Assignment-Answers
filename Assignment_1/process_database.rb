## This program reads three databases (gene_information.tsv, seed_stock_data.tsv and cross_data.tsv),
## substracts 7 grams of seeds in objects of class SeedStock, writes the result in a new file with the
## same structure as the original; and checks if there are linked genes in the cross database. 

require './gene_class.rb'
require './seedstock_class.rb'
require './cross_class.rb'

# Checks if there are the right number of arguments in the command line and create the objects from the files
if (ARGV.length == 4)  
	list_genes = create_genes(ARGV[0])
	list_seedstock = create_seedstock(list_genes, ARGV[1])
	list_crosses = create_cross(list_seedstock, ARGV[2])
	
	unless (list_genes && list_seedstock && list_crosses)  # Checks that the objects have been created correctly
		puts "Wrong files."
		puts "You should introduce gene_information.tsv, seed_stock_data.tsv and cross_data.tsv and the new file you want to create (in that order)."
		exit
	end
	
else
	puts "There are input files missing."
	puts "You should introduce gene_information.tsv, seed_stock_data.tsv and cross_data.tsv and the new file you want to create (in that order)."
	exit
end


# Write in a new file the result of substracting certain grams of seeds in a file with the same format as the original
out_file = File.open(ARGV[3], "w")  
out_file.puts("Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining")  # Header
list_seedstock.each_value do |seed|
	seed.planting_seeds(7)  # Call the method in the class to do the subtraction
	out_file.puts("#{seed.seed_stock}\t#{seed.mutant_geneID.ID}\t#{Time.now.strftime("%d/%m/%Y")}\t#{seed.storage}\t#{seed.grams_remaining}")
end


# Check if there are linked genes
count = 0
list_crosses.each_value do |cross|
	linked = cross.chisquare()
	count += 1  if (linked)  # The linked genes are stored in an array
end


# Printing final report in screen...
puts
puts "Final Report:"
if (count > 0)
	list_genes.each_value do |gene|
		if (gene.linked_to)
			puts "#{gene.name} is linked to #{gene.linked_to}"
		end
	end
else
	puts "There are no linked genes" 
end
