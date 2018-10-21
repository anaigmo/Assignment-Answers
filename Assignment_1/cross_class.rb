# Hybrid cross class

require './seedstock_class.rb'
require './gene_class.rb'

class Cross
  
  attr_accessor :parent1  
  attr_accessor :parent2
  attr_accessor :F2_wild
  attr_accessor :F2_P1
  attr_accessor :F2_P2
  attr_accessor :F2_P1P2
  
  def initialize (params = {})
    @parent1 = params.fetch(:parent1, 'unknown parent 1')
    @parent2 = params.fetch(:parent2, 'unknown parent 2')
    @F2_wild = params.fetch(:F2_wild, "0000000").to_f
    @F2_P1 = params.fetch(:F2_P1, "0000000").to_f
    @F2_P2 = params.fetch(:F2_P2, "0000000").to_f
    @F2_P1P2 = params.fetch(:F2_P1P2, "0000000").to_f
  end
  
  def chisquare()
    total = @F2_wild + @F2_P1 + @F2_P2 + @F2_P1P2
    exp_value = Array.new([9.0/16*total, 3.0/16*total, 3.0/16*total, 1.0/16*total])
    
    chis = ((@F2_wild-exp_value[0])**2)/exp_value[0] + ((@F2_P1-exp_value[1])**2)/exp_value[1] + ((@F2_P2-exp_value[2])**2)/exp_value[2] + ((@F2_P1P2-exp_value[3])**2)/exp_value[3]

    if (chis > 3.84) 
      puts "Recording: #{@parent1.mutant_geneID.name} is genetically linked to #{@parent2.mutant_geneID.name} with a chisquare score #{chis}"
      return [@parent1.mutant_geneID.name, @parent2.mutant_geneID.name]
    else
      return false
    end
    
  end
  
  
end


def create_cross(list_seeds, in_file)
    
  first_line = true
  list_crosses = {}
  
  File.open(in_file, "r").each do |line|
    if (first_line)
      first_line = false
      next
    
    else
      elements = line.split("\t")
      if (list_seeds.include? elements[1] and list_seeds.include? elements[0])
        new_cross = Cross.new(:parent1 => list_seeds[elements[0]],
                                 :parent2 => list_seeds[elements[1]],
                                 :F2_wild => elements[2],
                                 :F2_P1 => elements[3],
                                 :F2_P2 => elements[4],
                                 :F2_P1P2 => elements[5])
        list_crosses[elements[0]] = new_cross
        
      else
        new_cross = SeedStock.new(:F2_wild => elements[2],
                                 :F2_P1 => elements[3],
                                 :F2_P2 => elements[4],
                                 :F2_P1P2 => elements[5])
        list_crosses[elements[0]] = new_cross
      end
    end
  end
  
  return list_crosses
  
end