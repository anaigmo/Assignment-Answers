require 'bio'
require 'stringio'


## makeblastdb -in short_db/rep_TAIR10_short_seq.fa -dbtype 'nucl' -out short_db/rep_TAIR10_short_seq

## ----- FUNCTIONS ----- ##

def check_type_sequence(database)
  
  seq = []
  first = true
  File.open(database, "r").each do |line|
    
    if line[0] == '>' and not first
      break
    elsif first
      first = false
      next
    else
      seq.push(line)
    end 
    
  end
  
  seq = seq.join('')
  
  seq = Bio::Sequence.auto(seq)
  
  return(seq.guess.to_s.split('::')[-1])

end



def create_factory(name_db, type)
  
  raw_name = name_db.split('.')[0]  # Remove the extension
  
  if type == 'blastp' or type == 'blastx'
    `makeblastdb -in #{name_db} -dbtype 'prot' -out #{raw_name}`
  elsif type == 'blastn' or type == 'tblastn'
    `makeblastdb -in #{name_db} -dbtype 'nucl' -out #{raw_name}`
  end
  
  factory = Bio::Blast.local(type, raw_name)
  
  return factory
  
end



def create_query_db(name_db)
  
  query_db = Bio::FlatFile.auto(name_db)
  
  return query_db
  
end



def find_best_hit(seq_query, factory)
  
  report = factory.query(seq_query)  # blast of query sequence in factory db
    
    first = true
    best_hit = false
    report.each_hit do |hit|
      if first 
        best_hit = hit
        #first = false  ESTO HABRÍA QUE PENSARLO BIEN, SI NO CON BREAK VA UN PELIN MAS RAPIDO
        break
      elsif hit.evalue < best_hit.evalue  # if another hit is better than the first
        best_hit = hit
      end
    end
    
    if best_hit and best_hit.evalue < 1e-05  # minimun e-value to be considered significant
      id = seq_query.definition.split('|')[0]
      bh_id = best_hit.definition.split('|')[0]
      return [id, bh_id]
    else
      return false
    end
end



def find_reciprocal_best_hits(db1, db2)
  
  type1 = check_type_sequence(db1)
  type2 = check_type_sequence(db2)
  
  query_db1 = create_query_db(db1)
  query_db2 = create_query_db(db2)
  
  if type1 == type2 and type2 == 'AA'
    factory1 = create_factory(db2, 'blastp')
    factory2 = create_factory(db1, 'blastp')
    
  elsif type1 == type2 and type2 == 'NA'
    factory1 = create_factory(db2, 'blastn')
    factory2 = create_factory(db1, 'blastn')
    
  elsif type1 == 'NA' and type2 == 'AA'
    factory1 = create_factory(db2, 'blastx')
    factory2 = create_factory(db1, 'tblastn')
    
  elsif type1 == 'AA' and type2 == 'NA'
    factory1 = create_factory(db2, 'tblastn')
    factory2 = create_factory(db1, 'blastx')
  end
  
  
  # First search
  
  best_hits1 = {}
  best_hits2 = {}
  query_db1.each do |seq|  # looks for best hit in factory db for each sequence in query_db
      
    best_hit = find_best_hit(seq, factory1)
    
    if best_hit
      best_hits1[best_hit[0]] = best_hit[1] if best_hit  # stores the gene id correspondance
      best_hits2[best_hit[1]] = false  # To reduce the search on the next database
      
      puts("#{best_hit[0]} -> #{best_hit[1]}")  ## ESTO SE PUEDE QUITAR
    end
        
  end
  
  
  # Second search
  
  query_db2.each do |seq|
    
    # Doesn't do blast if is not a best hit in the first list
    next unless best_hits2.has_key?(seq.definition.split('|')[0])
    best_hit = find_best_hit(seq, factory2)
    best_hits2[best_hit[0]] = best_hit[1] if best_hit  # stores the gene id correspondance
      
    puts("#{best_hit[0]} -> #{best_hit[1]}") if best_hit  ## ESTO SE PUEDE QUITAR
  end
  
  rec_best_hits = {}
  
  best_hits1.each_key do |key|
    if key == best_hits2[best_hits1[key]]
      rec_best_hits[key] = best_hits1[key]
    end  
  end
  
  return rec_best_hits
  
end


def write_repot(rec_best_hits, db1_name, db2_name)
  
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

rec_best_hits = find_reciprocal_best_hits(db1_name, db2_name)

write_repot(rec_best_hits, db1_name, db2_name)












