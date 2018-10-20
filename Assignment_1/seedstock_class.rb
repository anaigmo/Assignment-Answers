# Seed stock class

require './gene_class.rb'

class SeedStock
  
  attr_accessor :seed_stock  
  attr_accessor :mutant_geneID
  attr_accessor :last_planted
  attr_accessor :storage
  attr_accessor :grams_remaining
  
  def initialize (params = {})
    @seed_stock = params.fetch(:seed_stock, 'unknown seed')
    @mutant_geneID = params.fetch(:mutant_geneID, "0000000")
    @last_planted = params.fetch(:last_planted, "00/00/0000")
    @storage = params.fetch(:storage, 'unknown')
    @grams_remaining = params.fetch(:grams_remaining, 0)
    @grams_remaining = @grams_remaining.to_i
  end
  
  def planting_seeds(number)
    if (@grams_remaining > number)
      @grams_remaining = @grams_remaining - number
    else
      @grams_remaining = 0
      puts "There are no more grams of seed #{@seed_stock}"
    end
  end
  
end


def create_seedstock(list_genes, in_file)
   
  first_line = true
  list_seeds = {}
  
  File.open(in_file, "r").each do |line|
    if (first_line)
      first_line = false
      next
    
    else
      elements = line.split("\t")
      if (list_genes.include? elements[1])
        new_seed = SeedStock.new(:seed_stock => elements[0],
                                 :mutant_geneID => list_genes[elements[1]],
                                 :last_planted => elements[2],
                                 :storage => elements[3],
                                 :grams_remaining => elements[4])
        list_seeds[elements[0]] = new_seed
      else
        new_seed = SeedStock.new(:seed_stock => elements[0],
                                 :last_planted => elements[2],
                                 :storage => elements[3],
                                 :grams_remaining => elements[4])
        list_seeds[elements[0]] = new_seed
      end
    end
  end
  
  return list_seeds
  
end