from PyPDF2 import PdfMerger

def merge(input_paths, output_path):
  merger = PdfMerger()
  
  for path in input_paths:
    merger.append(path.decode('utf-8'))

  merger.write(output_path.decode('utf-8'))
  merger.close()
  
  return True
