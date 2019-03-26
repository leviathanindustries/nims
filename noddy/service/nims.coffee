
import fs from 'fs'
import unzip from 'unzip'
import Future from 'fibers/future'

API.service ?= {}
API.service.nims = {}

nims_dataset = new API.collection index: API.settings.es.index + "_nims", type:"dataset"
nims_imeji = new API.collection index: API.settings.es.index + "_nims", type:"imeji"
nims_pubman = new API.collection index: API.settings.es.index + "_nims", type:"pubman"
nims_pdf = new API.collection index: API.settings.es.index + "_nims", type:"pdf"

samurai_person = new API.collection index: API.settings.es.index + "_nims_samurai", type:"person"

API.add 'service/nims',
  get: () ->
    q = API.collection._translate this.queryParams
    res = API.es.call 'POST', API.settings.es.index + '_nims,' + API.settings.es.index + '_nims_samurai/_search', q
    res.q = q if API.settings.dev
    return res
  post: () ->
    q = API.collection._translate this.bodyParams
    res = API.es.call 'POST', API.settings.es.index + '_nims,' + API.settings.es.index + '_nims_samurai/_search', q
    res.q = q if API.settings.dev
    return res

API.add 'service/nims/suggest',
  get: () ->
    q = API.collection._translate this.queryParams
    res = API.es.call 'POST', API.settings.es.index + '_nims,' + API.settings.es.index + '_nims_samurai/_search', q
    starts = []
    suggestions = []
    try m = this.queryParams.q
    try m ?= q.query.filtered.query.bool.must[0]['query_string'].query
    m ?= ''
    m = m.replace(/\*/g,'').replace(/~/g,'')
    for rec in res.hits.hits
      try delete rec.txts
      vals = API.convert.json2txt rec, {list: true}
      for v in vals
        if v and typeof v is 'string' and v.indexOf(m) isnt -1 and v.indexOf('http') isnt 0
          if v.indexOf(m) is 0 and v not in starts
            starts.push v
          else
            if v.length-m.length > 100
              try
                p = v.split m
                if p[0].length > 50
                  p[0] = p[0].substring(0,50)
                after = 100 - p[0].length
                if p[1].length > after
                  p[1] = p[1].substring(0,after)
                v = p[0] + m + p[1]
            if v not in suggestions
              suggestions.push v
    for s in suggestions
      starts.push(s) if s not in starts
    return starts

API.add 'service/nims/count', get: () -> return API.es.count API.settings.es.index + "_nims"
API.add 'service/nims/count/:key', get: () -> return API.es.count API.settings.es.index + "_nims", undefined, this.urlParams.key
API.add 'service/nims/terms/:key', get: () -> return API.es.terms API.settings.es.index + "_nims", undefined, this.urlParams.key, undefined, undefined, false
API.add 'service/nims/min/:key', get: () -> return API.es.min API.settings.es.index + "_nims", undefined, this.urlParams.key
API.add 'service/nims/max/:key', get: () -> return API.es.max API.settings.es.index + "_nims", undefined, this.urlParams.key
API.add 'service/nims/range/:key', get: () -> return API.es.range API.settings.es.index + "_nims", undefined, this.urlParams.key
API.add 'service/nims/keys', get: () -> return API.es.keys API.settings.es.index + "_nims"

API.add 'service/nims/dataset', () -> return nims_dataset.search this
API.add 'service/nims/imeji', () -> return nims_imeji.search this
API.add 'service/nims/pubman', () -> return nims_pubman.search this
API.add 'service/nims/pdf', () -> return nims_pdf.search this

#API.add 'service/nims/:type/count', get: () -> return API.es.count API.settings.es.index + "_nims", this.urlParams.type
#API.add 'service/nims/:type/count/:key', get: () -> return API.es.count API.settings.es.index + "_nims", this.urlParams.type, this.urlParams.key
#API.add 'service/nims/:type/terms/:key', get: () -> return API.es.terms API.settings.es.index + "_nims", this.urlParams.type, this.urlParams.key, undefined, undefined, false
#API.add 'service/nims/:type/min/:key', get: () -> return API.es.min API.settings.es.index + "_nims", this.urlParams.type, this.urlParams.key
#API.add 'service/nims/:type/max/:key', get: () -> return API.es.max API.settings.es.index + "_nims", this.urlParams.type, this.urlParams.key
#API.add 'service/nims/:type/range/:key', get: () -> return API.es.range API.settings.es.index + "_nims", this.urlParams.type, this.urlParams.key
#API.add 'service/nims/:type/keys', get: () -> return API.es.keys API.settings.es.index + "_nims", this.urlParams.type

API.add 'service/nims/read/dataset', get: () -> return API.service.nims.read.dataset this.queryParams.raw?, not this.queryParams.tdm?
API.add 'service/nims/read/imeji', get: () -> return API.service.nims.read.imeji this.queryParams.raw?, not this.queryParams.tdm?
API.add 'service/nims/read/pubman', get: () -> return API.service.nims.read.pubman this.queryParams.raw?, not this.queryParams.tdm?
API.add 'service/nims/read/pdf', get: () -> return API.service.nims.read.pdf()
API.add 'service/nims/read/csv', get: () -> return API.service.nims.read.csv this.queryParams.file

API.add 'service/nims/image/analyse/:id', get: () -> return API.service.nims.analyse(this.urlParams.id)

API.add 'service/nims/look/:ft', get: () -> return API.service.nims.look(this.urlParams.type, this.queryParams.raw?)
API.add 'service/nims/phash', get: () -> return API.service.nims.phash()
API.add 'service/nims/xml', get: () -> return {statusCode: 200, headers: {'content-type':'application/xml; charset=UTF-8'}, body: fs.readFileSync('/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-narrow/api-fwk_depositUploadReq.xml').toString()}
API.add 'service/nims/bulk', get: () -> return API.service.nims.bulk this.queryParams.types, not this.queryParams.remove?
API.add 'service/nims/pdfs', get: () -> return API.service.nims.read.pdfs()
API.add 'service/nims/clear', get: () -> return API.service.nims.clear()


API.add 'service/nims/samurai', () ->  return samurai_person.search this
API.add 'service/nims/samurai/:person', get: () ->  return samurai_person.get this.urlParams.person
API.add 'service/nims/samurai/:person/img', get: () -> return samurai_person.get(this.urlParams.person).portrait_url + (if this.queryParams.size then '?size=' + this.queryParams.size else '')
API.add 'service/nims/samurai/:person/thumbnail', get: () -> return samurai_person.get(this.urlParams.person).portrait_url + '?size=thumbnail'
API.add 'service/nims/samurai/ids', get: () ->  return API.service.nims.samurai.ids()
#API.add 'service/nims/samurai/scrape', get: () ->  return API.service.nims.samurai.scrape()
#API.add 'service/nims/samurai/fix', get: () ->  return API.service.nims.samurai.fix()
#API.add 'service/nims/samurai/search', get: () ->  return API.service.nims.samurai.search this.queryParams.q, this.queryParams.page



API.service.nims.analyse = (id) ->
  rec = nims_imeji.get id
  img = rec.thumbnailImageUrl
  return {}

API.service.nims.samurai = {}
API.service.nims.samurai.search = (q='',page) ->
  try
    url = 'https://samurai.nims.go.jp/profiles.json?q=' + q
    url += '&page=' + page if page
    API.log 'Searching NIMS Samurai for ' + url
    res = HTTP.call 'GET', url
    return res.data
  catch
    return []

# there are 832 researchers in samurai, 84 pages of results in samurai, and it takes the page param from 1 to 84 to parse them
# because their name tags are used to get their page content, that is what is meant by IDs here, not their actual user IDs (which seem to be no use)
API.service.nims.samurai._ids = []
API.service.nims.samurai.ids = () ->
  if API.service.nims.samurai._ids.length
    return API.service.nims.samurai._ids
  else if samurai_person.count()
    samurai_person.each '*', (rec) -> API.service.nims.samurai._ids.push rec._id
    return API.service.nims.samurai._ids
  else
    ids = []
    page = 1
    while page < 85
      results = API.service.nims.samurai.search '', page
      page += 1
      for res in results
        ru = res.url.split('/').pop()
        ids.push(ru) if ru not in ids
    API.service.nims.samurai._ids = ids
    return ids

API.service.nims.samurai.find = (q) ->
  try
    res = samurai_person.find q
    if res
      return res
    else
      try
        return API.service.nims.samurai.get API.service.nims.samurai.search(q)[0].url, false
      catch
        return undefined
  catch
    return undefined

API.service.nims.samurai.get = (uid,save=true) ->
  # uid is user name NOT their ID e.g
  # https://samurai.nims.go.jp/profiles/ohmura_takahito.json
  # and an image of each user is at (works without thumbnail param and is not much different in size)
  # https://samurai.nims.go.jp/profiles/ohmura_takahito.jpg?size=thumbnail
  uid = uid.split('/').pop().replace('.json','') # in case we get the full URL here
  local = samurai_person.get uid
  if local
    return local
  else
    try
      url = 'https://samurai.nims.go.jp/profiles/' + uid + '.json'
      API.log 'GETting NIMS Samurai for ' + url
      res = HTTP.call 'GET', url
      res.data._id = uid
      res.data = API.service.nims.samurai.fix res.data
      samurai_person.insert(res.data) if save
      return res.data
    catch
      return undefined

API.service.nims.samurai.scrape = (remove=true) ->
  recs = []
  for id in API.service.nims.samurai.ids()
    recs.push API.service.nims.samurai.get id, false
    console.log recs.length + ' samurai'
  if recs.length
    samurai_person.remove('*') if remove
    samurai_person.insert recs
  return recs.count

API.service.nims.samurai.fix = (rec) ->
  fixed = []
  _fix = (rec) ->
    _fixlist = (list, name) ->
      ls = []
      for o of list
        if name is 'authors'
          try list[o][o].groups = _fixlist(list[o][o].groups) if list[o][o].groups?
        if name is 'articles'
          try
            issns = []
            issns.push(list[o][o].journal.issn[i][i]) for i of list[o][o].journal.issn
            list[o][o].journal.issn = issns
          try list[o][o].authors = _fixlist list[o][o].authors, 'authors'
        ls.push list[o][o]
      return ls
    for list in ['groups','keywords','articles']
      rec[list] = _fixlist(rec[list], list) if rec[list]?
    return rec
  if rec
    return _fix rec
  else
    samurai_person.each '*', (rec) -> fixed.push _fix(rec)
  if fixed.length
    samurai_person.remove('*')
    samurai_person.insert fixed
  return fixed.length

API.service.nims.phash = () ->
  done = 0
  nims_imeji.each 'NOT phash:*', (rec) ->
    try
      phash = API.img.phash rec.thumbnailImageUrl
      nims_imeji.update(rec._id, {phash: phash}) if phash
    done += 1
  return done

API.service.nims.read = {}
API.service.nims.read.imeji = (raw=false,tdm=true) ->
  # can read imeji from /home/cloo/nims-ngdr-development-2018/Metadata/imeji/metadata_xml
  # each file is a list of items - each item should be a unique entry
  clean = (val, k) ->
    try
      if k is 'imeji:items'
        ir = []
        for i in val['imeji:item']
          try
            for s of val.$
              i[s] =  val.$[s]
          ir.push i
        val = ir
    try
      if typeof val is 'object' and not _.isArray val
        for v of val
          if v.indexOf('imeji:') isnt -1
            val[v.split(':')[1]] = val[v]
            delete val[v]
    return val
  clean = false if raw is true
  folder = '/home/cloo/nims-ngdr-development-2018/Metadata/imeji/metadata_xml'
  recs = []
  for file in fs.readdirSync(folder) #[fs.readdirSync(folder)[0]]
    res = API.convert.xml2json fs.readFileSync(folder + '/' + file), undefined, clean
    res = res['imeji:items']
    for r of res
      try
        res[r].metadata = res[r].metadataSet.metadata
        delete res[r].metadataSet
      try
        res[r].text = res[r].fulltext
        delete res[r].fulltext
      res[r] = API.service.nims.tdm(res[r]) if tdm
      try res[r].phash = API.img.phash res[r].thumbnailImageUrl
      recs.push res[r]
      console.log recs.length + ' imeji'
  return recs

API.service.nims.read._dataset = (dir,rec={},raw=false) ->
  dir ?= '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-survey'
  rec.dir ?= dir
  rec.name ?= dir.split('/').pop()
  rec.files ?= []
  rec.parsed ?= []
  files = if fs.lstatSync(dir).isDirectory() then fs.readdirSync(dir) else [dir.split('/').pop()]
  clean = (val, k) ->
    try val = val.tagLink[0]
    return val
  clean = false if raw is true
  for file in files
    df = dir + '/' + file
    rec.files.push(df) if fs.existsSync(df) and not fs.lstatSync(df).isDirectory()
    try
      fl = file.toLowerCase()
      fls = fl.split('.')[0]
      if fl.indexOf('template') is -1 and fl.indexOf('example' ) is -1
        if fl.indexOf('.xml') isnt -1
          try
            x = API.convert.xml2json fs.readFileSync(df), undefined, clean
            kx = _.keys x
            #if kx.length is 1 and (kx[0].toLowerCase() is fls.toLowerCase() or (fls.toLowerCase().split('').pop() is 's' and kx[0].toLowerCase() is fls.toLowerCase().slice(0, -1)))
            if kx.length is 1
              x = x[kx[0]]
            rec[fls] ?= {}
            for k of x
              rec[fls][k] = x[k]
            rec.parsed.push df
        else if fl.indexOf('.csv') isnt -1
          rec.csv ?= []
          try
            cs = API.service.nims.read.csv df
            rec.csv.push(cs) if cs
          rec.parsed.push df
        else if fl.indexOf('.zip') isnt -1 or (fs.existsSync(df) and fs.lstatSync(df).isDirectory())
          zd = dir + '/' + file.replace('.zip', '').replace('.ZIP','')
          if fl.indexOf('.zip') isnt -1
            if not fs.existsSync zd
              waiting = true
              fs.createReadStream(df).pipe(unzip.Extract({ path: zd})).on('close', () -> waiting = false)
              while waiting
                future = new Future()
                Meteor.setTimeout (() -> future.return()), 1000
                future.wait()
            else
              zd = false
          if zd isnt false
            z = API.service.nims.read._dataset zd, {}, raw
            for zk of z
              if zk is 'files' or zk is 'parsed'
                for zf in z[zk]
                  rec[zk].push zf
              else
                rec[zk] ?= z[zk]
        else if fl.indexOf('.jpg') isnt -1 or fl.indexOf('.png') isnt -1
          if fl.indexOf('thumb') isnt -1 # only do something with the thumbnail for now
            console.log df
            #rec.parsed.push df
            #rec.attachment = fs.readFileSync file # check how to read the file into the index
  return rec

API.service.nims.read.dataset = (raw=false,tdm=true) ->
  #dir ?= '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-survey' # can also do specimen
  folders = [
    '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization',
    '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/specimen'
  ]
  recs = []
  for folder in folders #[folders[0]]
    for dir in fs.readdirSync(folder) #[fs.readdirSync(folder)[0]]
      rec = API.service.nims.read._dataset folder + '/' + dir, {}, raw
      if not raw
        delete rec.dir
        delete rec.files
        delete rec.parsed
        try
          for ky of rec['api-fwk_deposituploadreq']
            rec[ky] = rec['api-fwk_deposituploadreq'][ky]
          delete rec['api-fwk_deposituploadreq']
        try rec.tools = rec.tools.tool
        try delete rec['']
        try
          rec.atts = rec.attachment
          delete rec.attachment
      if tdm
        rc = JSON.parse JSON.stringify rec
        try delete rc.files
        try delete rc.parsed
        res = API.service.nims.tdm rc
        for r of res
          rec[r] ?= res[r]
      recs.push rec
      console.log recs.length + ' dataset'
  return recs

API.service.nims.read.csv = (fn) ->
  # primary.csv and id.csv do not yet actually parse out to any useful values
  # primary.csv is a list of keys with a list of values, should be oriented the other way to be a useful csv
  # id.csv is datapoint values, but with comments at the top with preceding hashes, which also does not parse
  if fn is 'primary'
    fn = '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-survey/data062.A/primary.csv'
  if fn is 'id'
    fn = '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-survey/data062.A/data062.A/id.csv'
  fn ?= '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-survey/data062.A/data062.A/id.csv'
  if fn.indexOf('primary.') isnt -1
    csv = fs.readFileSync(fn).toString()
    rec = file: fn.split('/').pop(), data: []
    rec.title = rec.file.split('.')[0]
    for line in csv.replace(/\r\n/g,'\n').split('\n')
      lp = line.split ','
      rs = {}
      try rs[lp[0].trim()] = lp[1].trim().toString()
      rec.data.push(rs) if not _.isEmpty rs
    return rec
  else if fn.indexOf('id.') isnt -1 or fn.indexOf('DataBase01.') isnt -1
    # there is also one at characterization/XPS_survey/DataBase01.104/DataBase01.104/DataBase01.104/DataBase01.104.csv
    # which is the same, but no way to know from the name
    csv = fs.readFileSync(fn).toString()
    rec = file: fn.split('/').pop(), title: '', legend: '', comments: [], keys: [], data: [], lines: []
    for line in csv.replace(/\r\n/g,'\n').split('\n')
      if line.indexOf('#') isnt 0
        rec.lines.push line
      else
        # there is no general way yet to get column names out of NIMS CSVs. Pull some for example where known
        if line.indexOf('#dimension') is 0
          # dimension seems to be a list of keys, but they then have definitions on the lines that follow, so dimension not useful right now
          keys = line.split ','
          #for k in keys
          #  if k isnt '#dimension' and k and k not in rec.keys
          #    rec.keys.push k
        else if line.indexOf('#x') is 0 or line.indexOf('#y') is 0
          try
            lp = line.split ','
            lv = lp[1].trim()
            if lp.length > 2 and lp[2]
              try lv += ' (' + lp[2].trim() + ')'
            rec.keys.push(lv) if lv not in rec.keys
        else if line.indexOf('#legend') is 0
          try rec.legend = line.split(',')[1].trim().toString()
        else if line.indexOf('#title') is 0
          try rec.title = line.split(',')[1].trim().toString()
        rec.comments.push line.replace('#','').trim().toString()
    for uline in rec.lines
      lineparts = uline.split ','
      dt = {}
      idx = 0
      for part in lineparts
        if idx < rec.keys.length and part
          dt[rec.keys[idx].trim()] = part.trim().toString()
        idx += 1
      rec.data.push(dt) if not _.isEmpty dt
    return rec
  else
    # e.g. there is a file called characterization/XPS_narrow/MIDATA001.107/MIDATA001.107/MIDATA001.107/MIDATA001.107.csv
    # which is like the id.csv, but it has 7 rows but only x and y defined, so cannot know all the column names
    # and there is one at characterization/STEM/HAADF/HAADF/HAADF.csv
    # which has the same comments style as the id.csv but contains just a single line of many data values
    # for now not running for csv we cannot handle well
    #rec = file: fn.split('/').pop().toString()
    #rec.title = rec.file.split('.')[0].toString()
    #rec.data = API.convert.csv2json csv
    #return rec
    return undefined

API.service.nims.read.pdf = (pid, onlytext=false, onlyenglish=true) ->
  #try
  pid ?= '1275565'
  dir = '/home/cloo/pubman/pdfs/' + pid
  if fs.lstatSync(dir).isDirectory()
    pdf = false
    for file in fs.readdirSync dir
      if pdf is false and file.toLowerCase().indexOf('.pdf') isnt -1 and (onlyenglish is false or API.tdm.language(file) is 'english')
        pdf = dir + '/' + file
    #pdf ?= '/home/cloo/pubman/1275565/Transactions_of_the_Materials_Research_Society_of_JapanNo5_OCR_180.pdf'
    if pdf
      text = API.convert.pdf2txt fs.readFileSync pdf
      if onlytext
        return text
      else
        res = {text: text.toLowerCase().replace(/[^\x00-\x7F]/g, " "), name: pdf.split('/').pop()}
        res.language = API.tdm.language res.text.substr(0,(if res.text.length < 100 then res.text.length else 100))
        # google translate of japanese content has not been good enough to use
        #if res.language isnt 'english'
        #  res.translated = API.use.google.cloud.translate res.text, 'ja', 'en'
        if res.language is 'english'
          return API.service.nims.tdm res
  return undefined

API.service.nims.read.pdfs = (bulk=false) ->
  dir = '/home/cloo/pubman/pdfs'
  folders = fs.readdirSync dir
  pdfs = if bulk then [] else 0
  for folder in folders
    #if pdfs.length < 1
    exists = nims_pdf.get folder
    console.log(folder + ' already exists, not running') if not bulk and exists
    if bulk or not exists
      try
        pdf = API.service.nims.read.pdf folder
        if pdf?
          pdf._id = folder
          if bulk
            pdfs.push pdf
            console.log pdfs.length + ' pdfs'
          else
            nims_pdf.insert pdf
            pdfs++
            console.log pdfs + ' pdfs'
  if not bulk
    API.mail.send to: 'alert@cottagelabs.com', subject: 'NIMS import PDFs non-bulk done ' + pdfs, text: pdfs.toString()
  return pdfs

API.service.nims.read.pubman = (raw=false,tdm=true) ->
  dir = '/home/cloo/nims-ngdr-development-2018/Metadata/Pubman/pubman_metadata'
  files = fs.readdirSync dir
  recs = []
  for file in [files[3]]
    json = API.convert.xml2json fs.readFileSync(dir + '/' + file), undefined, not raw
    for rec in json.root.item
      try rec.clpid = rec.href.split(':').pop()
      try
        rec.clpdfpid = rec.components.component.href.split(':').pop()
        if rec.clpdfpid
          rec.text = API.service.nims.read.pdf rec.clpdfpid, true
      rec = API.service.nims.translate(rec) if not raw
      rec = API.service.nims.tdm(rec) if tdm
      recs.push rec # only save the ones could find text for, at the moment, as only have some of the pubman files?
      console.log recs.length + ' pubman'
  return recs

API.service.nims.tdm = (rec, google=false) ->
  if not rec.text and not rec.translated
    txt = API.convert.json2txt rec, {numbers: false}
    txts = []
    for t in txt.split(' ')
      t = t.toLowerCase().split('/').pop().split(':').pop().replace('#','')
      txts.push(t) if t.length > 1 and t not in txts
    txt = txts.join(' ')
  try rec.keywords = API.tdm.keywords (rec.translated ? rec.text ? txts), {ngrams:[1,2], min:2, stem:true, cutoff:0.8, stopWords: ['imeji','terms','internal','identifier','text','number','mr','mrs']}

  # on keywords this can find humans and orgs and some nonsense, on the full text it finds lots of nonsense
  # but we would already know they are humans or orgs so this may not be useful - could be useful on more textual content
  # however we can get wikipedia URLs in some cases, and knowledge graph MIDs, which could be useful, and from wikipedia URLs can categorise the entity
  if google and (rec.text or rec.translated)
    try
      rec.ggl = API.use.google.cloud.language (rec.translated ? rec.text), 'entities'
      if rec.ggl?.entities?
        for e in rec.ggl.entities
          if e.metadata?.mid?
            try
              knowledge = API.use.google.knowledge.retrieve e.metadata.mid
              try knowledge.name = e.name
              if knowledge?
                rec.knowledge ?= []
                try rec.knowledge.push knowledge
          if e.metadata?.wikipedia_url?
            try
              categorise = API.tdm.categorise e.metadata.wikipedia_url.split('/').pop()
              if categorise?
                rec.categorise ?= []
                try categorise.name = e.name
                try rec.categorise.push categorise
                if categorise.wikibase
                  try
                    wikidata = API.use.wikidata.retrieve categorise.wikibase
                    if wikidata?
                      rec.wikidata ?= []
                      try rec.wikidata.push wikidata

  try rec.entities = API.tdm.entities rec.translated ? rec.text ? txts
  if rec.entities?
    try delete rec.entities.other
    persons = []
    for tp of rec.entities
      if tp in ['person','organisation','location']
        for entity in rec.entities[tp]
          if entity.value
            sp = tp is 'person' and samurai_person.find('full_name.en:'+entity.value+' OR articles.authors.full_name.en:'+entity.value)
            try entity.categorise = API.tdm.categorise entity.value
            ln = entity.value.split(' ').length
            if entity.categorise.status is 'error'
              delete entity.categorise
            else if entity.categorise?.wikibase? and (tp isnt 'person' or (ln > 1 and ln < 4) or sp)
              try delete entity.categorise.keywords
              try entity.wikidata = API.use.wikidata.retrieve entity.categorise.wikibase
              #try delete entity.wikidata.infokeys
              try delete entity.wikidata.info
            try
              entity.knowledge = API.use.google.knowledge.find entity.value
              delete entity.knowledge if (if tp is 'person' then 'Person' else if tp is 'organisation' then 'Organization' else 'Place') not in entity.knowledge['@type']
          if entity.value and tp is 'person' and ln > 1 and ln < 4
            persons.push entity
    try rec.entities.person = persons

  try rec.terms = API.service.nims.terms rec.translated ? rec.text ? txts

  try rec.chemicals = API.use.chemicaltagger (rec.translated ? rec.text ? txts), {types: 'NounPhrase'}

  #try delete rec.text
  try delete rec.translated
  #try delete rec.txts
  try delete rec.language
  return rec

API.service.nims.bulk = (types=['dataset','imeji','pubman'], remove=true) ->
  #return false

  types = types.split(',') if typeof types is 'string'
  types = ['dataset']
  #types = ['imeji']
  #types = ['pubman']
  #types = ['pdf']
  #remove = false

  status = {total: 0, errors: 0}

  if 'dataset' in types
    datasets = []
    datasets = API.service.nims.read.dataset()
    if datasets.length
      console.log datasets.length
      nims_dataset.remove('*') if remove
      status.dataset = nims_dataset.insert(datasets)
      status.total += datasets.length

  if 'imeji' in types
    imejis = []
    imejis = API.service.nims.read.imeji()
    if imejis.length
      console.log imejis.length
      nims_imeji.remove('*') if remove
      status.imeji = nims_imeji.insert(imejis)
      status.total += imejis.length

  if 'pubman' in types
    pubmans = []
    pubmans = API.service.nims.read.pubman()
    if pubmans.length
      console.log pubmans.length
      nims_pubman.remove('*') if remove
      status.pubman = nims_pubman.insert(pubmans)
      status.total += pubmans.length

  if 'pdf' in types
    pdfs = []
    pdfs = API.service.nims.read.pdfs(true)
    if pdfs.length
      console.log pdfs.length
      nims_pdf.remove('*') if remove
      status.pdf = nims_pdf.insert(pdfs)
      status.total += pdfs.length

  for k of status
    if k not in ['total','errors']
      sd = {records: status[k].records}
      if status[k].responses[0].data.errors
        sd.errors = 0
        sd.items = []
        for item in status[k].responses[0].data.items
          if item.index?.status isnt 201
            sd.errors += 1
            status.errors += 1
            if not item.index?.error? or item.index.error not in sd.items
              sd.items.push item.index?.error ? item
      status[k] = sd
  API.mail.send to: 'alert@cottagelabs.com', subject: 'NIMS import ' + status.total + ' error ' + status.errors, text: JSON.stringify(status, "", 2)
  return status

API.service.nims.look = (file='csv', raw) ->
  file = '/home/cloo/nims-ngdr-development-2018/Sample_Datasets/2019-01-31/characterization/AES-survey/data062.A/primary.csv' if file is 'csv'
  txt = fs.readFileSync file
  if raw
    return
      statusCode: 200,
      headers: {'content-type':(if file.indexOf('.csv') isnt -1 then 'text/plain' else 'application/xml') + '; charset=UTF-8'},
      body: txt.toString()
  else
    return if file.indexOf('.csv') isnt -1 then API.convert.csv2json(txt) else if file.indexOf('.xml') isnt -1 then API.convert.xml2json(txt) else ''

API.service.nims.clear = () ->
  return false
  nims_dataset.remove '*'
  nims_imeji.remove '*'
  nims_pubman.remove '*'
  return true

API.service.nims.translate = (rec) ->
  if rec.properties
    for p of rec.properties[0]
      rec[p] = rec.properties[0][p] if p isnt '$'
    delete rec.properties
  if rec.relations
    rels = []
    rels.push(r.href) for r in rec.relations
    rec.relations = rels
  if rec.resources
    ress = []
    ress.push(rs.href) for rs in rec.resources
    rec.resources = ress
  if rec.components
    cmp = []
    for cp in rec.components
      if cp.component
        for comp in cp.component
          if comp.properties
            for p of comp.properties[0]
              comp[p] = comp.properties[0][p]
            delete comp.properties
          try delete component['md-records']
          cmp.push comp
    rec.components = cmp
  if rec['content-model-specific']?
    delete rec['content-model-specific']
  if rec['md-records']
    mds = []
    for md in rec['md-records']
      if md['md-record']
        for m in md['md-record']
          if m.publication
            for p in m.publication
              if p.subject?
                p.subject = p.subject[0] if _.isArray p.subject
                if typeof p.subject is 'string'
                  p.subject = [{type: 'unknown', value: p.subject}]
                try p.subject[0].value = p.subject[0].value.split(',')
              if p.alternative?
                p.alternative = p.alternative[0] if _.isArray p.alternative
                if typeof p.alternative is 'string'
                  p.alternative = [{type: 'eterms:OTHER', value: p.alternative}]
              if p.abstract?
                p.abstract = p.abstract[0] if _.isArray p.abstract
                if typeof p.abstract is 'string'
                  p.abstract = [{lang: 'eng', value: p.abstract}]
                try rec.text ?= p.abstract[0].value
          mds.push m
    rec.records = mds
    delete rec['md-records']
  return rec


API.service.nims.terms = (text) ->
  res = {}
  for t of API.service.nims._terms
    for term in API.service.nims._terms[t]
      if text.indexOf(term) isnt -1
        res[t] ?= []
        res[t].push term # this will create a unique list of the terms in a doc, but not a count of how often they appear

  res._samurai_names = []
  if API.service.nims._terms._samurai_names.length is 0
    samurai_person.each '*', {include:'full_name'}, (rec) -> API.service.nims._terms._samurai_names.push rec.full_name.en
  for nm in API.service.nims._terms._samurai_names
    parts = nm.split(',')
    save = true
    p1 = text.indexOf(parts[0].toLowerCase().replace(' ',''))
    if p1 isnt -1 and parts.length > 1
      p2 = text.indexOf(parts[1].toLowerCase().replace(' ',''))
      if p2 isnt -1
        diff = p1 - p2
        diff = diff * -1 if diff < 0
        if diff < 20
          res._samurai_names.push nm
    else if p1 isnt -1
      res._samurai_names.push nm
  return res

API.service.nims._terms = {}
API.service.nims._terms._samurai_names = []
API.service.nims._terms._analysis_fields = [
  'bio property',
  'chemical state',
  'crystallography',
  'distribution',
  'electronic property',
  'environmental analysis',
  'failure analysis',
  'impurity analysis',
  'magnetic property',
  'morphology',
  'optical property',
  'physical property',
  'qualitative analysis',
  'quantitative analysis',
  'theoretical simulation',
  'other (free description)'
]
API.service.nims._terms._characterization_methods = [
  'charge distribution',
  'chromatography',
  'dilatometry',
  'electrochemical',
  'mechanical',
  'microscopy',
  'optical',
  'osmometry',
  'profilometry',
  'scattering and diffraction',
  'spectrometry',
  'spectroscopy',
  'thermochemical',
  'tomography',
  'ultrasonic',
  'viscometry',
  'alpha spectrometry',
  'amperometry',
  'analytical electron microscopy',
  'atom probe tomography',
  'atomic force microscopy',
  'calorimetry',
  'compression tests',
  'confocal microscopy',
  'creep tests',
  'critical and supercritical chromatography',
  'dielectric and impedance spectroscopy',
  'differential refractive index',
  'differential scanning calorimetry',
  'differential thermal analysis',
  'dynamic light scattering',
  'dynamic mechanical analysis',
  'dynamic mechanical spectroscopy',
  'electron backscatter diffraction',
  'electron energy-loss spectroscopy',
  'electron probe microanalysis',
  'ellipsometry',
  'energy dispersive x-ray spectometry',
  'environmental scanning electron',
  'EXAFS',
  'Fourier-transform infrared spectroscopy',
  'fractography',
  'freezing point depression osmometry',
  'gamma spectrometry',
  'gas-phase chromatography',
  'hardness',
  'ion chromatography',
  'ion mobility spectrometry',
  'IR_FTIR spectrometry',
  'light scattering',
  'liquid-phase chromatography',
  'mass spectrometry',
  'membrane osmometry',
  'microcalorimetry',
  'microscopy',
  'field emission electron probe',
  'nanoindentation',
  'neutron (elastic)',
  'neutron (inelastic)',
  'NEXAFS',
  'NMR',
  'optical microscopy',
  'photoluminescence microscopy',
  'potentiometry',
  'pulsed electroacoustic method',
  'optical	quasi-elastic light scattering',
  'Raman',
  'scanning Auger electron microscopy',
  'scanning electron microscopy',
  'scanning Kelvin probe',
  'scanning probe microscopy',
  'scanning transmission electron microscopy',
  'scanning tunneling microscopy',
  'secondary ion mass spectrometry',
  'shear or torsion tests',
  'small angle x-ray scattering',
  'small-angle neutron scattering',
  'synchrotron',
  'tension tests',
  'thermogravimetry',
  'transmission electron microscopy',
  'vapor pressure depression osmometry',
  'voltammetry',
  'wear tests',
  'x-ray absorption spectroscopy',
  'x-ray diffraction',
  'x-ray emission spectroscopy',
  'x-ray flourescence spectrometry',
  'x-ray optical interferometry',
  'x-ray photoelectron spectroscopy',
  'x-ray reflectivity',
  'x-ray tomography',
  'x-ray topography',
  'XPS variable kinetic',
  'XRD grazing incidence'
]
API.service.nims._terms._computational_methods = [
  'boundary tracking or level set',
  'CALPHAD',
  'cellular automata',
  'cluster expansion',
  'crystal plasticity',
  'density functional theory or electronic structure',
  'dislocation dynamics',
  'finite element analysis',
  'machine learning',
  'molecular dynamics',
  'Monte Carlo methods',
  'multiscale simulations',
  'phase-field calculations',
  'reverse Monte Carlo',
  'self-consistent field theory',
  'simulated experiment',
  'scattering theory',
  'statistical mechanics'
]
API.service.nims._terms._data_origins = [
  'experiments',
  'informatics and data science',
  'other',
  'simulations',
  'theory'
]
API.service.nims._terms._material_types = [
  'biological',
  'biomaterials',
  'ceramics',
  'metals and alloys',
  'metamaterials',
  'molecular fluids',
  'organic compounds',
  'organometallics',
  'polymers',
  'semiconductors',
  'carbides',
  'cements',
  'nitrides',
  'oxides',
  'perovskites',
  'silicates',
  'Al-containing',
  'commercially pure metals',
  'Cu-containing',
  'Fe-containing',
  'intermetallics',
  'Mg-containing',
  'Ni-containing',
  'rare earths',
  'refractories',
  'steels',
  'superalloys',
  'Ti-containing',
  'amines',
  'carboxylic acids',
  'nitriles',
  'copolymers',
  'elastomers',
  'homopolymers',
  'liquid crystals',
  'polymer blends',
  'rubbers',
  'thermoplastics',
  'thermosets',
  'extrinsic',
  'II-VI',
  'III-V',
  'intrinsic',
  'n-type',
  'nitrides',
  'p-type',
  'silicon'
]
API.service.nims._terms._measurement_environments = [
  'in air',
  'in liquid',
  'in vacuum',
  'in inactive gas',
  'in high pressure',
  'in magnetic field',
  'at low temperature',
  'other (free description)'
]
#API.service.nims._terms._processing_environments = API.service.nims._terms._measurement_environments
API.service.nims._terms._properties_addressed = [
  'chemical',
  'colligative',
  'corrosion',
  'crystallographic',
  'durability',
  'electrical',
  'kinetic',
  'magnetic',
  'mechanical',
  'optical',
  'rheological',
  'structural',
  'thermodynamic',
  'toxicity',
  'transport',
  'composition',
  'impurity concentration',
  'molecular masses and distributions',
  'crevice',
  'erosion-corrosion',
  'galvanic',
  'high temperature',
  'intergranular',
  'pitting',
  'selective leaching',
  'stress corrosion',
  'uniform',
  'crystalline lattice',
  'orientation maps',
  'space groups',
  'textures',
  'aging',
  'coefficient of friction',
  'thermal shock resistance',
  'wear resistance',
  'band structure',
  'conductivity',
  'dielectric constant and spectra',
  'dielectric dispersion',
  'electrostrictive',
  'piezoelectric',
  'power conversion efficiency',
  'pyroelectric',
  'resistivity',
  'spin polarization',
  'superconductivity',
  'thermoelectric',
  'grain growth',
  'phase evolution',
  'phase transitions and ordering',
  'coercivity',
  'Curie temperature',
  'magnetization',
  'permeability',
  'saturation magnetization',
  'susceptibility',
  'acoustic emission',
  'compression response',
  'creep',
  'deformation mechanisms',
  'ductility',
  'elasticity',
  'fatigue',
  'flexural response',
  'fracture behavior',
  'fracture toughness',
  'hardness',
  'impact response',
  'phonon modes',
  'plasticity',
  'Poisson\'s ratio',
  'shear response',
  'strength',
  'stress-strain behavior',
  'tensile response',
  'tensile strength',
  'viscoelasticity',
  'yield strength',
  'index of refraction',
  'luminescence',
  'photoconductivity',
  'complex modulus',
  'viscoelasticity',
  'viscosity',
  'calorimetry profile',
  'critical temperatures',
  'crystallization temperature',
  'density',
  'glass transition temperature',
  'grain boundary energies',
  'heat capacity',
  'heat of fusion',
  'heat of solidification',
  'interfacial energies',
  'liquid crystal phase transition',
  'molar volume',
  'phase diagram',
  'phase stability',
  'specific heat',
  'superconductivity',
  'surface energies',
  'temperature',
  'melting temperature',
  'thermal conductivity',
  'thermal decomposition temperature',
  'thermal expansion',
  'diffusivity',
  'grain boundary diffusivity',
  'interdiffusion',
  'intrinsic diffusivity',
  'mobilities',
  'surface diffusivity',
  'tracer diffusivity'
]
API.service.nims._terms._structural_features = [
  'composites',
  'defects',
  'engineered structures',
  'interfacial',
  'microstructures',
  'molecular structure',
  'morphologies',
  'phases',
  'biological or green',
  'fiber-reinforced',
  'metal-matrix',
  'nanocomposites',
  'particle-reinforced',
  'polymer-matrix',
  'structural',
  'cracks',
  'crazing',
  'debonding',
  'disclinations',
  'dislocations',
  'inclusions',
  'interstitials',
  'point defects',
  'pores',
  'vacancies',
  'voids',
  'grain boundaries',
  'interfacial surface area',
  'magnetic domain walls',
  'ordering boundaries',
  'phase boundaries',
  'stacking faults',
  'surfaces',
  'twin boundaries',
  'cellular',
  'clustering',
  'compound',
  'crystallinity',
  'defect structures',
  'dendritic',
  'dispersion',
  'eutectic',
  'grains',
  'nanocrystalline',
  'particle distribution',
  'particle shape',
  'polycrystalline',
  'polydispersity',
  'porosity',
  'precipitates',
  'quasicrystalline',
  'single crystal',
  'twinned',
  'alternating copolymer',
  'block copolymer',
  'dendrimer',
  'end-group composition',
  'functionalization',
  'gradient copolymer',
  'long-chain branching',
  'random copolymer',
  'short-chain branching',
  'surfactants',
  'tacticity',
  'aligned',
  'amorphous',
  'clusters',
  'complex fluids',
  'glass',
  'layered',
  'nanoparticles or nanotubes',
  'one-dimensional',
  'open-framework',
  'particles or colloids',
  'porous',
  'quantum dots or wires',
  'random',
  'semicrystalline',
  'thin film',
  'two-dimensional',
  'wires',
  'woven',
  'crystalline',
  'disordered',
  'gas',
  'liquid',
  'melt',
  'metastable',
  'nonequilibrium',
  'ordered'
]
API.service.nims._terms._synthesis_and_processing = [
  'annealing and homogenization',
  'casting',
  'deposition and coating',
  'forming',
  'fractionation',
  'mechanical and surface',
  'powder processing',
  'quenching',
  'reactive',
  'self-assembly',
  'solidification',
  'aging',
  'homogenization',
  'mechanical mixing',
  'melt mixing',
  'normalizing',
  'recrystallization',
  'stress relieving',
  'tempering',
  'ultrasonication',
  'centrifugal casting',
  'continuous casting',
  'die casting',
  'investment casting',
  'sand castingslip',
  'slip casting',
  'vacuum arc melting',
  'atomic layer deposition',
  'carbon evaporation coating',
  'chemical vapor deposition',
  'electrodeposition',
  'electron beam deposition',
  'evaporation',
  'gold-sputter coating',
  'ink-jet deposition',
  'ion beam deposition',
  'Langmuir-Blodgett film deposition',
  'physical vapor deposition',
  'plasma spraying',
  'pulsed laser deposition',
  'spin coating',
  'splatter',
  'sputter coating',
  'cold rolling',
  'drawing',
  'extrusion',
  'forging',
  'hot pressing',
  'hot rolling',
  'milling',
  'molding',
  'doctor blade or blade coating',
  'focused ion beam',
  'joining',
  'lithography',
  'polishing',
  'sectioning',
  'thermal plasma processing',
  'atomization',
  'ball milling',
  'centrifugal disintegration',
  'hot pressing',
  'sintering',
  'sponge iron process',
  'air cooled _ quench',
  'brine quench',
  'furnace cooled',
  'gas cooled',
  'ice quench',
  'liquid nitrogen quench',
  'oil quench',
  'water quench',
  'addition polymerization',
  'condensation polymerization',
  'curing',
  'dissolving _ etching',
  'drying',
  'in-situ polymerization',
  'post-polymerization modification',
  'reductive roasting',
  'solution processing',
  'solvent casting',
  'micelle formation',
  'monolayer formation',
  'self-assembly-assisted grafting',
  'crystallization',
  'directional solidification',
  'injection molding',
  'precipitation',
  'rapid solidification',
  'seeded solidification',
  'single crystal solidification',
  'vacuum molding',
  'zone refining'
]
