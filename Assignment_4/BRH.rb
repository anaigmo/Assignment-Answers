## ------------------------------------------- Assignment 4 -------------------------------------------  ##
#
# This program has been created by Ana Iglesias Molina for the subject Bioinformatics Programming Challenges.
#
# This program takes two multifasta files as databases, does blast against one another, saves the reciprocal
# best hits and prints it in a file called 'Reciprocal_best_hits.tsv'.
# The criteria to accept a best hit is an e-value of 1e-6, an overlap length of at least half the length
# of the query sequence and a percent of identity of 30%. I have chosen those values according to what
# I have read in the literature. The e-value is not tough, but above 1e-05 it seems it is not robust enough,
# and under 1e-6 is considered necesary for nucleotide blast. Regarding the overlapping length, it's the most
# common value I've seen. 70-75% of the length of the sequence could be also used, but for a first approximation
# to look for orthologues I preferred not to be so tough, same happens with the value of identity.

require 'bio'
require 'stringio'


## ----- FUNCTIONS ----- ##

def check_type_sequence(database)
  # This function takes a multifasta file, extracts the first sequence and finds out the type of
  # sequences it contains. It returns 'AA' for aminoacids and 'NA' for nucleotides.
  
  seq = []
  first = true
  File.open(database, 'r').each do |line|
    
    if line[0] == '>' and not first  # finish in second sequence
      break
    elsif first
      first = false
      next
    else
      seq.push(line)
    end 
    
  end
  
  seq = seq.join('')
  
  seq = Bio::Sequence.auto(seq)  # Transforms the sequence in a Bio::Sequence object
  
  return(seq.guess.to_s.split('::')[-1])  # Returns 'AA' or 'NA'

end



def create_factory(name_db, type)
  # This functions creates a database for blast from a multifasta file 'name_db'. It needs
  # to know if the database contains protein or nucleotide sequences. It creates de files in
  # the directory the multifasta is with a shell command, and then creates the factory object
  # and returns it. 
  
  raw_name = name_db.split('.')[0]  # Remove the extension
  
  # Create the necessary files to create the factory object
  if type == 'blastp' or type == 'blastx'
    `makeblastdb -in #{name_db} -dbtype 'prot' -out #{raw_name}`
  elsif type == 'blastn' or type == 'tblastn'
    `makeblastdb -in #{name_db} -dbtype 'nucl' -out #{raw_name}`
  end
  
  factory = Bio::Blast.local(type, raw_name)  
  
  return factory
  
end



def create_query_db(name_db)
  # This function creates an object to iterate every sequence in a multifasta file 'name_db'
  # and returns it
  
  query_db = Bio::FlatFile.auto(name_db)
  
  return query_db
  
end



def find_reciprocal_best_hits(db1, db2)
  # This function does blast to both databases from the other to find the reciprocal best hits.
  # It takes the names of the databases and returns a hash with the correspondance of genes.
  
  # First, it creates the objects query and factory to do the blast. 
  type1 = check_type_sequence(db1)
  type2 = check_type_sequence(db2)
  
  query_db1 = create_query_db(db1)
  query_db2 = create_query_db(db2)
  
  if type1 == type2 and type2 == 'AA'
    factory1 = create_factory(db2, 'blastp')
    factory2 = create_factory(db1, 'blastp')
    blast_case = 1
    
  elsif type1 == type2 and type2 == 'NA'
    factory1 = create_factory(db2, 'blastn')
    factory2 = create_factory(db1, 'blastn')
    blast_case = 1
    
  elsif type1 == 'NA' and type2 == 'AA'
    factory1 = create_factory(db2, 'blastx')
    factory2 = create_factory(db1, 'tblastn')
    blast_case = 2
    
  elsif type1 == 'AA' and type2 == 'NA'
    factory1 = create_factory(db2, 'tblastn')
    factory2 = create_factory(db1, 'blastx')
    blast_case = 3
  end
  
  
  # First search
  # The results of the best hits in this search are saved in two ways. The query gen as key and its best
  # hit as value in the hash called 'best_hits1', and the best hit as key in the hash 'best_hits2'.
  # Having all the possible keys saved in best_hits2 will save time in the next search. 
  
  best_hits1 = {}
  best_hits2 = {}
  query_db1.each do |seq|  # looks for best hit in factory db for each sequence in query_db
      
    report = factory1.query(seq)  # blast of query sequence in factory db
    
    # Restrictions to alignments: evalue under 1e-6
    next unless report.hits[0] and report.hits[0].evalue < 1e-6
    
    if blast_case == 1 or blast_case == 3
      percent_overlap = report.hits[0].overlap/seq.length.to_f
      percent_identity = report.hits[0].identity/seq.length.to_f
    elsif blast_case == 2
      percent_overlap = report.hits[0].overlap*3/seq.length.to_f
      percent_identity = report.hits[0].identity*3/seq.length.to_f
    end
    
    # More restrictions to alignments: overlap over 50% and identity over 30%
    next unless percent_overlap >= 0.5 and percent_identity >= 0.3
    
    # Get id of genes
    id_query = seq.definition.split('|')[0]
    id_bh = report.hits[0].definition.split('|')[0]
    
    best_hits1[id_query] = id_bh   # stores the gene id correspondance
    best_hits2[id_bh] = false  # To reduce the search in the next database
      
    puts("Best hit found: #{id_query} -> #{id_bh}")
    puts("%overlap: #{percent_overlap}\t%identity: #{percent_identity}\tevalue: #{report.hits[0].evalue}")
    puts()
      
  end
  
  
  # Second search
  # The best hits are saved ase value of its correspondent key in 'best_hits2'

  query_db2.each do |seq|
    
    # Doesn't do blast if the sequence is not a best hit in the first list
    next unless best_hits2.has_key?(seq.definition.split('|')[0]) 
    
    report = factory2.query(seq)  # blast of query sequence in factory db
    
    next unless report.hits[0] and report.hits[0].evalue < 1e-6
    
    if blast_case == 1 or blast_case == 2
      percent_overlap = report.hits[0].overlap/seq.length.to_f
      percent_identity = report.hits[0].identity/seq.length.to_f
    
    elsif blast_case == 3
      percent_overlap = report.hits[0].overlap*3/seq.length.to_f
      percent_identity = report.hits[0].identity*3/seq.length.to_f
      
    end
    
    next unless percent_overlap >= 0.5 and percent_identity >= 0.3
    
    id_query = seq.definition.split('|')[0]
    id_bh = report.hits[0].definition.split('|')[0]
    
    best_hits2[id_query] = id_bh   # stores the gene id correspondance
      
    puts("Best hit found: #{id_query} -> #{id_bh}")
    puts("%overlap: #{percent_overlap}\t%identity: #{percent_identity}\tevalue: #{report.hits[0].evalue}")
    puts()
    
  end
  
  # Checks reciprocal best hits in both best hits hashes
  rec_best_hits = {}
  
  best_hits1.each_key do |key|
    if key == best_hits2[best_hits1[key]]
      rec_best_hits[key] = best_hits1[key]
    end  
  end
  
  return rec_best_hits
  
end



def write_repot(rec_best_hits, db1_name, db2_name)
  # This function prints in a tabular format file the reciprocal best hits found
  
  puts("The reciprocal best hits found will be saved in Reciprocal_best_hits.tsv")
  
  out_file = File.open("Reciprocal_best_hits.tsv", "w")
  out_file.puts("#{db1_name}\t#{db2_name}")

  rec_best_hits.each_key do |key|
    out_file.puts("#{key}\t#{rec_best_hits[key]}")
  end

end



## ----- MAIN ----- ##

abort ("Missing proteome files.") unless ARGV.length == 2
db1_name = ARGV[0]
db2_name = ARGV[1]

# Find reciprocal best hits
puts("Finding best reciprocal hits, it will take a while. ")
rec_best_hits = find_reciprocal_best_hits(db1_name, db2_name)

# And print it in a file called 'Reciprocal_best_hits.tsv
write_repot(rec_best_hits, db1_name, db2_name)
