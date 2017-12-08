/*                                                                                                                     
 
              @     ,@
             #@@   @@@
             @@@@@@@@@;
             @@@@@@@@@@
            :@@@@@@@@@@
            @@@@@@@@@@@
            @@@@@@@@@@@;
            @@@@@@@@@@@@
            @@@@@@@@@@@@
           `+@@@@@@@@@@+                                                                                                
 
         .@@`           #@,
     .@@@@@@@@@@@@@@@@@@@@@@@@:
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@     @@   @@      #@   @           @
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@   @@@@  @#      #@   @           @
    ;@@@@@@@@@@@@@@@@@@@@@@@@@@'        @     @   @# @#      #@   @ #@@@   @@@@  @@@  @@@@@  @@@   @@  @   @  @@   @ @@
        .+@@@@@@@@@@@@@@@@+.            @@@@  @   @@ @#      #@   @ #@  @ @@  @  @  @  @@   @  @  @ `@  @ @  @  @  @@
       '`                  `,#           @@@@ @   @@ @#      #@   @ #@  @ @#  @ @@@@@  @    @     @  @  @ @  @@@@  @`
     ,@@@@ '@@@@@@@@@@@@@ .@@@@;           @  @   @@ @#      #@   @ #@  @ @@  @ @@     @ `  @     @  @  @@@  @     @
    #@@@@@@ @@@@@  +@@@@  +@@@@@@       @@@@   @@@@  @@@@@   `@@@@@ #@  @ #@ @@  @  @  @    @@ @  @  @   @   @  @  @
   @@@@@@@@  ,#.    `#;   @@@@@@@@'      @@     @@   @@@@@     @@,  #@  @  @@ @   @@  @@     #@    @@    @    @@   @
  ;#@@@@@@@@             @@@@@@@@@#,              @
       ,@@@@+           @@@@@+`
          .@@`        `@@@@                                          © www.sqlundercover.com
         +@@@@        @@@@@+
        @@@@@@@      @@@@@@@@#
         @@@@@@@    @@@@@@,
           :@@@@@' ;@@@@`
             `@@@@ @@@+
                @#:@@
                  @@
                  @`
                  #                                                                                                     
 


Writing Your Own Encryption Routines In SQL  ....And Crackng Them

By David Fowler
www.sqlundercover.com
*/



--DEMO 1, Boolean Logic

DECLARE @Var1 CHAR(1) = 'a'
DECLARE @Var2 CHAR(1) = 'b'

IF @Var1 = 'a' AND @Var2 = 'b'
PRINT 'Statement equates to TRUE'
ELSE
PRINT 'Statement equates to FALSE'




--DEMO 2, Bitwise Logic

--& 
SELECT	1 & 1  AS 'Both 1', 
		1 & 0  AS 'One is 1', 
		0 & 0  AS 'Both 0'


--|
SELECT	1 | 1  AS 'Both 1', 
		1 | 0  AS 'One is 1', 
		0 | 0  AS 'Both 0'


--^
SELECT	1 ^ 1  AS 'Both 1', 
		1 ^ 0  AS 'One is 1', 
		0 ^ 0  AS 'Both 0'


--Bitwise when applied to a byte


SELECT 220 & 177 



-----------------------------------------------------------------------------
--  XOR Cypher
-----------------------------------------------------------------------------

--ASCII representation of 'GroupBy'
SELECT ASCII('G')



--XOR The ASCII code for 'G' with a simple key of 123
SELECT CHAR(ASCII('G') ^ 123)




--to decrypt simply XOR the cyphertext with the key
SELECT CHAR(ASCII('<') ^ 123)



--let's put that together into a routine

CREATE OR ALTER PROC EncryptData_XOR
 @PlainText VARCHAR(MAX),
 @Key TINYINT
AS
BEGIN

--variable to hold cyphertext
DECLARE @CypherText VARCHAR(MAX)
SET @CypherText = ''
 
--loop through the plaintext one character at a time, building the cyphertext
WHILE DATALENGTH(@CypherText) < DATALENGTH(@PlainText)
BEGIN
	SET @CypherText = @CypherText + CHAR(ASCII(SUBSTRING(@PlainText,DATALENGTH(@CypherText)+1, 1)) ^ @Key)
END
 
PRINT @CypherText
 
END




--To encrypt 'GroupBy'

EXEC EncryptData_XOR 'GroupBy',23


--To decrypt


EXEC EncryptData_XOR 'PexbgUn',123







--Brute Force Attack

DECLARE @Key INT
SET @Key = 0
WHILE @Key <= 255
BEGIN
PRINT 'Key ' + CAST(@Key AS VARCHAR)
EXEC EncryptData_XOR 'PexbgUn', @Key
SET @Key = @Key + 1
END






------------------------------------------------------------------------------------------------------
--XOR - Caesar Collaboration
------------------------------------------------------------------------------------------------------


--SQL example of the Caesar Cypher

SELECT CHAR(ASCII('G') + 2)


--To decrypt, reverse the processs
SELECT CHAR(ASCII('I') - 2)



--combine XOR and Caesar, first apply XOR and then shift 
SELECT CHAR((ASCII('G') + 2) ^ 123)


--to decrypt
SELECT CHAR((ASCII('2') ^ 123) - 2)




CREATE OR ALTER PROC [dbo].[EncryptData_CaesarXOR]
@PlainText VARCHAR(MAX),
@Key TINYINT,
@Shift TINYINT,
@Decrypt BIT = 0,
@CypherText VARCHAR(MAX) = '' OUTPUT
AS
BEGIN
  SET @CypherText = ''
 
  WHILE DATALENGTH(@CypherText) < DATALENGTH(@PlainText)
  BEGIN
     IF @Decrypt = 0
     SET @CypherText = @CypherText + CHAR((ASCII(SUBSTRING(@PlainText,DATALENGTH(@CypherText)+1, 1))+ @Shift) ^ @Key)
     ELSE
     SET @CypherText = @CypherText + CHAR((ASCII(SUBSTRING(@PlainText,DATALENGTH(@CypherText)+1, 1)) ^ @Key) - @Shift)
  END
 
PRINT @CypherText
END




--encrypt
EXEC EncryptData_CaesarXOR @PlainText = 'GroupBy', @Key = 210, @Shift = 2, @Decrypt = 0



--decrypt
EXEC EncryptData_CaesarXOR @PlainText = '›¦£¥ –©', @Key = 210, @Shift = 2, @Decrypt = 1



--Substitution cypher example

EXEC EncryptData_CaesarXOR @PlainText = 'AAABBBCCCABC',@Key = 113, @Shift = 2, @Decrypt = 0






--Statisical Attack

EXEC EncryptData_CaesarXOR 'The author of a government review into work practices is calling for the end of the "cash in hand economy".
Matthew Taylor, whose report is out on Tuesday, said cash jobs like window cleaning and decorating were worth up to £6bn a year, much of it untaxed.
Instead, the work should be paid through "payment platforms", Mr Taylor told BBC economics editor Kamal Ahmed.
The review, commissioned by Theresa May, also tackles low-paid work, zero hours contracts and the gig economy.
Mr Taylor, who is chief executive of the Royal Society of Arts and a former Tony Blair advisor, is set to call for cash jobs to be paid through platforms such as credit cards, contactless payments and PayPal.
This would make it harder for customers and workers to avoid paying tax.
Properly protected
The recommendations are part of a much wider review into modern working practices, including the gig economy.
Mr Taylors report recommends a new category of worker called a "dependent contractor", who should be given extra protections by firms like Uber and Deliveroo.
It also says low-paid workers should not be "stuck" at the minimum living wage or face insecurity.
Minimum wage push for gig economy workers
Deliveroo moves on benefits for riders
What is the gig economy?
Speaking at its launch, the prime minister will say the Taylor report confronts issues that "go right to the heart of this governments agenda and right to the heart of our values as a people".
Mrs May will say: "I am clear that this government will act to ensure that the interests of employees on traditional contracts, the self-employed and those people working in the gig economy are all properly protected."',
 10, 2




 --The first thing we need to do is analyse the frequency of characters
 CREATE TABLE #CharacterFrequency
(Character VARCHAR(10),
Frequency INT,
FrequencyRank INT,
PredictedCharacter CHAR(1))



--populare the frequency table

DECLARE @frequency INT
DECLARE @Character VARCHAR(10)
DECLARE @TempText VARCHAR(MAX) = '\`m(i}|`{~({b(i(c{rm~zemz|(~mrams(az|{(s{~g(x~io|aom(a(oiddazc(b{~(|`m(mzl({b(|`m(.oi`(az(`izl(mo{z{eq.:Ei||`ms(\iqd{~$(s`{m(~mx{~|(a({}|({z(\}mliq$(ial(oi`(f{n(dagm(sazl{s(odmizazc(izl(lmo{~i|azc(sm~m(s{~|`(}x(|{(¯2nz(i(qmi~$(e}o`({b(a|(}z|ipml:Az|mil$(|`m(s{~g(`{}dl(nm(xial(|`~{}c`(.xiqemz|(xdi|b{~e.$(E~(\iqd{~(|{dl(NNO(mo{z{eao(mla|{~(Gieid(I`eml:\`m(~mrams$(o{eeaa{zml(nq(\`m~mi(Eiq$(id{(|iogdm(d{s%xial(s{~g$(vm~{(`{}~(o{z|~io|(izl(|`m(cac(mo{z{eq:E~(\iqd{~$(s`{(a(o`amb(mpmo}|arm({b(|`m(^{qid(_{oam|q({b(I~|(izl(i(b{~em~(\{zq(Ndia~(ilra{~$(a(m|(|{(oidd(b{~(oi`(f{n(|{(nm(xial(|`~{}c`(xdi|b{~e(}o`(i(o~mla|(oi~l$(o{z|io|dm(xiqemz|(izl(XiqXid:\`a(s{}dl(eigm(a|(`i~lm~(b{~(o}|{em~(izl(s{~gm~(|{(ir{al(xiqazc(|ip:X~{xm~dq(x~{|mo|ml\`m(~mo{eemzli|a{z(i~m(xi~|({b(i(e}o`(salm~(~mrams(az|{(e{lm~z(s{~gazc(x~io|aom$(azod}lazc(|`m(cac(mo{z{eq:E~(\iqd{~(~mx{~|(~mo{eemzl(i(zms(oi|mc{~q({b(s{~gm~(oiddml(i(.lmxmzlmz|(o{z|~io|{~.$(s`{(`{}dl(nm(carmz(mp|~i(x~{|mo|a{z(nq(ba~e(dagm(]nm~(izl(Lmdarm~{{:A|(id{(iq(d{s%xial(s{~gm~(`{}dl(z{|(nm(.|}og.(i|(|`m(eazae}e(darazc(sicm({~(biom(azmo}~a|q:Eazae}e(sicm(x}`(b{~(cac(mo{z{eq(s{~gm~Lmdarm~{{(e{rm({z(nmzmba|(b{~(~alm~S`i|(a(|`m(cac(mo{z{eqK_xmigazc(i|(a|(di}zo`$(|`m(x~aem(eaza|m~(sadd(iq(|`m(\iqd{~(~mx{~|(o{zb~{z|(a}m(|`i|(.c{(~ac`|(|{(|`m(`mi~|({b(|`a(c{rm~zemz|(icmzli(izl(~ac`|(|{(|`m(`mi~|({b({}~(rid}m(i(i(xm{xdm.:E~(Eiq(sadd(iq6(.A(ie(odmi~(|`i|(|`a(c{rm~zemz|(sadd(io|(|{(mz}~m(|`i|(|`m(az|m~m|({b(mexd{qmm({z(|~ila|a{zid(o{z|~io|$(|`m(mdb%mexd{qml(izl(|`{m(xm{xdm(s{~gazc(az(|`m(cac(mo{z{eq(i~m(idd(x~{xm~dq(x~{|mo|ml:.'
 
WHILE DATALENGTH(@TempText) > 0
BEGIN
  SET @Character = SUBSTRING(@TempText, 1,1)
  SET @frequency = DATALENGTH(@TempText) -DATALENGTH(REPLACE(@TempText,@Character,''))
 
  INSERT INTO #CharacterFrequency(Character,Frequency)
VALUES(@Character,@frequency)
 
  SET @TempText = REPLACE(@TempText,@Character,'')
END



SELECT * 
FROM #CharacterFrequency




--find frequency ranks
UPDATE #CharacterFrequency
SET FrequencyRank = a.FrequencyRank
FROM(SELECT Character, ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS FrequencyRank
FROM #CharacterFrequency) a
JOIN #CharacterFrequency b ON a.Character = b.Character


SELECT * 
FROM #CharacterFrequency
ORDER BY Frequency DESC



--We know that by far the most common character that we're expecting is the space (many encryption algorithms eliminate spaces or pad for this very reason)

UPDATE #CharacterFrequency
SET PredictedCharacter = ' '
WHERE FrequencyRank = 1


SELECT REPLACE('\`m(i}|`{~({b(i(c{rm~zemz|(~mrams(az|{(s{~g(x~io|aom(a(oiddazc(b{~(|`m(mzl({b(|`m(.oi`(az(`izl(mo{z{eq.:Ei||`ms(\iqd{~$(s`{m(~mx{~|(a({}|({z(\}mliq$(ial(oi`(f{n(dagm(sazl{s(odmizazc(izl(lmo{~i|azc(sm~m(s{~|`(}x(|{(¯2nz(i(qmi~$(e}o`({b(a|(}z|ipml:Az|mil$(|`m(s{~g(`{}dl(nm(xial(|`~{}c`(.xiqemz|(xdi|b{~e.$(E~(\iqd{~(|{dl(NNO(mo{z{eao(mla|{~(Gieid(I`eml:\`m(~mrams$(o{eeaa{zml(nq(\`m~mi(Eiq$(id{(|iogdm(d{s%xial(s{~g$(vm~{(`{}~(o{z|~io|(izl(|`m(cac(mo{z{eq:E~(\iqd{~$(s`{(a(o`amb(mpmo}|arm({b(|`m(^{qid(_{oam|q({b(I~|(izl(i(b{~em~(\{zq(Ndia~(ilra{~$(a(m|(|{(oidd(b{~(oi`(f{n(|{(nm(xial(|`~{}c`(xdi|b{~e(}o`(i(o~mla|(oi~l$(o{z|io|dm(xiqemz|(izl(XiqXid:\`a(s{}dl(eigm(a|(`i~lm~(b{~(o}|{em~(izl(s{~gm~(|{(ir{al(xiqazc(|ip:X~{xm~dq(x~{|mo|ml\`m(~mo{eemzli|a{z(i~m(xi~|({b(i(e}o`(salm~(~mrams(az|{(e{lm~z(s{~gazc(x~io|aom$(azod}lazc(|`m(cac(mo{z{eq:E~(\iqd{~(~mx{~|(~mo{eemzl(i(zms(oi|mc{~q({b(s{~gm~(oiddml(i(.lmxmzlmz|(o{z|~io|{~.$(s`{(`{}dl(nm(carmz(mp|~i(x~{|mo|a{z(nq(ba~e(dagm(]nm~(izl(Lmdarm~{{:A|(id{(iq(d{s%xial(s{~gm~(`{}dl(z{|(nm(.|}og.(i|(|`m(eazae}e(darazc(sicm({~(biom(azmo}~a|q:Eazae}e(sicm(x}`(b{~(cac(mo{z{eq(s{~gm~Lmdarm~{{(e{rm({z(nmzmba|(b{~(~alm~S`i|(a(|`m(cac(mo{z{eqK_xmigazc(i|(a|(di}zo`$(|`m(x~aem(eaza|m~(sadd(iq(|`m(\iqd{~(~mx{~|(o{zb~{z|(a}m(|`i|(.c{(~ac`|(|{(|`m(`mi~|({b(|`a(c{rm~zemz|(icmzli(izl(~ac`|(|{(|`m(`mi~|({b({}~(rid}m(i(i(xm{xdm.:E~(Eiq(sadd(iq6(.A(ie(odmi~(|`i|(|`a(c{rm~zemz|(sadd(io|(|{(mz}~m(|`i|(|`m(az|m~m|({b(mexd{qmm({z(|~ila|a{zid(o{z|~io|$(|`m(mdb%mexd{qml(izl(|`{m(xm{xdm(s{~gazc(az(|`m(cac(mo{z{eq(i~m(idd(x~{xm~dq(x~{|mo|ml:.'
,(SELECT Character FROM #CharacterFrequency WHERE PredictedCharacter = ' '),' ')
GO

\`m i}|`{~ {b i c{rm~zemz| ~mrams az|{ s{~g x~io|aom a oiddazc b{~ |`m mzl {b |`m .oi` az `izl mo{z{eq.:Ei||`ms \iqd{~$ s`{m ~mx{~| a {}| {z \}mliq$ ial oi` f{n dagm sazl{s odmizazc izl lmo{~i|azc sm~m s{~|` }x |{ ¯2nz i qmi~$ e}o` {b a| }z|ipml:Az|mil$ |`m s{~g `{}dl nm xial |`~{}c` .xiqemz| xdi|b{~e.$ E~ \iqd{~ |{dl NNO mo{z{eao mla|{~ Gieid I`eml:\`m ~mrams$ o{eeaa{zml nq \`m~mi Eiq$ id{ |iogdm d{s%xial s{~g$ vm~{ `{}~ o{z|~io| izl |`m cac mo{z{eq:E~ \iqd{~$ s`{ a o`amb mpmo}|arm {b |`m ^{qid _{oam|q {b I~| izl i b{~em~ \{zq Ndia~ ilra{~$ a m| |{ oidd b{~ oi` f{n |{ nm xial |`~{}c` xdi|b{~e }o` i o~mla| oi~l$ o{z|io|dm xiqemz| izl XiqXid:\`a s{}dl eigm a| `i~lm~ b{~ o}|{em~ izl s{~gm~ |{ ir{al xiqazc |ip:X~{xm~dq x~{|mo|ml\`m ~mo{eemzli|a{z i~m xi~| {b i e}o` salm~ ~mrams az|{ e{lm~z s{~gazc x~io|aom$ azod}lazc |`m cac mo{z{eq:E~ \iqd{~ ~mx{~| ~mo{eemzl i zms oi|mc{~q {b s{~gm~ oiddml i .lmxmzlmz| o{z|~io|{~.$ s`{ `{}dl nm carmz mp|~i x~{|mo|a{z nq ba~e dagm ]nm~ izl Lmdarm~{{:A| id{ iq d{s%xial s{~gm~ `{}dl z{| nm .|}og. i| |`m eazae}e darazc sicm {~ biom azmo}~a|q:Eazae}e sicm x}` b{~ cac mo{z{eq s{~gm~Lmdarm~{{ e{rm {z nmzmba| b{~ ~alm~S`i| a |`m cac mo{z{eqK_xmigazc i| a| di}zo`$ |`m x~aem eaza|m~ sadd iq |`m \iqd{~ ~mx{~| o{zb~{z| a}m |`i| .c{ ~ac`| |{ |`m `mi~| {b |`a c{rm~zemz| icmzli izl ~ac`| |{ |`m `mi~| {b {}~ rid}m i i xm{xdm.:E~ Eiq sadd iq6 .A ie odmi~ |`i| |`a c{rm~zemz| sadd io| |{ mz}~m |`i| |`m az|m~m| {b mexd{qmm {z |~ila|a{zid o{z|~io|$ |`m mdb%mexd{qml izl |`{m xm{xdm s{~gazc az |`m cac mo{z{eq i~m idd x~{xm~dq x~{|mo|ml:.


--now that we know what a space represents, we can look for a very common pattern, SPACE_a_SPACE
DECLARE @Text VARCHAR(MAX) = '\`m(i}|`{~({b(i(c{rm~zemz|(~mrams(az|{(s{~g(x~io|aom(a(oiddazc(b{~(|`m(mzl({b(|`m(.oi`(az(`izl(mo{z{eq.:Ei||`ms(\iqd{~$(s`{m(~mx{~|(a({}|({z(\}mliq$(ial(oi`(f{n(dagm(sazl{s(odmizazc(izl(lmo{~i|azc(sm~m(s{~|`(}x(|{(¯2nz(i(qmi~$(e}o`({b(a|(}z|ipml:Az|mil$(|`m(s{~g(`{}dl(nm(xial(|`~{}c`(.xiqemz|(xdi|b{~e.$(E~(\iqd{~(|{dl(NNO(mo{z{eao(mla|{~(Gieid(I`eml:\`m(~mrams$(o{eeaa{zml(nq(\`m~mi(Eiq$(id{(|iogdm(d{s%xial(s{~g$(vm~{(`{}~(o{z|~io|(izl(|`m(cac(mo{z{eq:E~(\iqd{~$(s`{(a(o`amb(mpmo}|arm({b(|`m(^{qid(_{oam|q({b(I~|(izl(i(b{~em~(\{zq(Ndia~(ilra{~$(a(m|(|{(oidd(b{~(oi`(f{n(|{(nm(xial(|`~{}c`(xdi|b{~e(}o`(i(o~mla|(oi~l$(o{z|io|dm(xiqemz|(izl(XiqXid:\`a(s{}dl(eigm(a|(`i~lm~(b{~(o}|{em~(izl(s{~gm~(|{(ir{al(xiqazc(|ip:X~{xm~dq(x~{|mo|ml\`m(~mo{eemzli|a{z(i~m(xi~|({b(i(e}o`(salm~(~mrams(az|{(e{lm~z(s{~gazc(x~io|aom$(azod}lazc(|`m(cac(mo{z{eq:E~(\iqd{~(~mx{~|(~mo{eemzl(i(zms(oi|mc{~q({b(s{~gm~(oiddml(i(.lmxmzlmz|(o{z|~io|{~.$(s`{(`{}dl(nm(carmz(mp|~i(x~{|mo|a{z(nq(ba~e(dagm(]nm~(izl(Lmdarm~{{:A|(id{(iq(d{s%xial(s{~gm~(`{}dl(z{|(nm(.|}og.(i|(|`m(eazae}e(darazc(sicm({~(biom(azmo}~a|q:Eazae}e(sicm(x}`(b{~(cac(mo{z{eq(s{~gm~Lmdarm~{{(e{rm({z(nmzmba|(b{~(~alm~S`i|(a(|`m(cac(mo{z{eqK_xmigazc(i|(a|(di}zo`$(|`m(x~aem(eaza|m~(sadd(iq(|`m(\iqd{~(~mx{~|(o{zb~{z|(a}m(|`i|(.c{(~ac`|(|{(|`m(`mi~|({b(|`a(c{rm~zemz|(icmzli(izl(~ac`|(|{(|`m(`mi~|({b({}~(rid}m(i(i(xm{xdm.:E~(Eiq(sadd(iq6(.A(ie(odmi~(|`i|(|`a(c{rm~zemz|(sadd(io|(|{(mz}~m(|`i|(|`m(az|m~m|({b(mexd{qmm({z(|~ila|a{zid(o{z|~io|$(|`m(mdb%mexd{qml(izl(|`{m(xm{xdm(s{~gazc(az(|`m(cac(mo{z{eq(i~m(idd(x~{xm~dq(x~{|mo|ml:.'
DECLARE @Counter INT = 1
DECLARE @TempText VARCHAR(MAX) = @text
DECLARE @Character CHAR(3)
DECLARE @Frequency INT
DECLARE @Space CHAR(1)

SET @Space = (SELECT character FROM #CharacterFrequency WHERE PredictedCharacter = ' ')

WHILE DATALENGTH(@Text) >= @Counter
BEGIN
SET @Character = SUBSTRING(@TempText, @Counter,3)
IF @Character LIKE (@Space + '_' + @Space)
BEGIN
IF NOT EXISTS (SELECT 1 FROM #CharacterFrequency WHERE Character = @Character)
BEGIN
SET @frequency = (DATALENGTH(@TempText) - DATALENGTH(REPLACE(@TempText,@Character,''))) / 3
INSERT INTO #CharacterFrequency(Character,Frequency)
VALUES(@Character,@frequency)
END
SET @TempText = @text
END
SET @Counter = @Counter + 1
END




--lets have a look a what that's found...
SELECT * FROM #CharacterFrequency




--update our frequency table to include the predicted a

UPDATE #CharacterFrequency
SET PredictedCharacter = 'a'
WHERE Character = SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) = 3 ORDER BY Frequency DESC),2,1)






DELETE FROM #CharacterFrequency WHERE LEN(character) > 1


SELECT * 
FROM #CharacterFrequency
ORDER BY FrequencyRank




--what further patterns can we look for?

--The most common three letter word is 'the'
--To identify 'n' and 'd' - the most common three letter word beginning with 'a' is 'and'


--so lets analyse three letter words....

DECLARE @Text VARCHAR(MAX) = '\`m(i}|`{~({b(i(c{rm~zemz|(~mrams(az|{(s{~g(x~io|aom(a(oiddazc(b{~(|`m(mzl({b(|`m(.oi`(az(`izl(mo{z{eq.:Ei||`ms(\iqd{~$(s`{m(~mx{~|(a({}|({z(\}mliq$(ial(oi`(f{n(dagm(sazl{s(odmizazc(izl(lmo{~i|azc(sm~m(s{~|`(}x(|{(¯2nz(i(qmi~$(e}o`({b(a|(}z|ipml:Az|mil$(|`m(s{~g(`{}dl(nm(xial(|`~{}c`(.xiqemz|(xdi|b{~e.$(E~(\iqd{~(|{dl(NNO(mo{z{eao(mla|{~(Gieid(I`eml:\`m(~mrams$(o{eeaa{zml(nq(\`m~mi(Eiq$(id{(|iogdm(d{s%xial(s{~g$(vm~{(`{}~(o{z|~io|(izl(|`m(cac(mo{z{eq:E~(\iqd{~$(s`{(a(o`amb(mpmo}|arm({b(|`m(^{qid(_{oam|q({b(I~|(izl(i(b{~em~(\{zq(Ndia~(ilra{~$(a(m|(|{(oidd(b{~(oi`(f{n(|{(nm(xial(|`~{}c`(xdi|b{~e(}o`(i(o~mla|(oi~l$(o{z|io|dm(xiqemz|(izl(XiqXid:\`a(s{}dl(eigm(a|(`i~lm~(b{~(o}|{em~(izl(s{~gm~(|{(ir{al(xiqazc(|ip:X~{xm~dq(x~{|mo|ml\`m(~mo{eemzli|a{z(i~m(xi~|({b(i(e}o`(salm~(~mrams(az|{(e{lm~z(s{~gazc(x~io|aom$(azod}lazc(|`m(cac(mo{z{eq:E~(\iqd{~(~mx{~|(~mo{eemzl(i(zms(oi|mc{~q({b(s{~gm~(oiddml(i(.lmxmzlmz|(o{z|~io|{~.$(s`{(`{}dl(nm(carmz(mp|~i(x~{|mo|a{z(nq(ba~e(dagm(]nm~(izl(Lmdarm~{{:A|(id{(iq(d{s%xial(s{~gm~(`{}dl(z{|(nm(.|}og.(i|(|`m(eazae}e(darazc(sicm({~(biom(azmo}~a|q:Eazae}e(sicm(x}`(b{~(cac(mo{z{eq(s{~gm~Lmdarm~{{(e{rm({z(nmzmba|(b{~(~alm~S`i|(a(|`m(cac(mo{z{eqK_xmigazc(i|(a|(di}zo`$(|`m(x~aem(eaza|m~(sadd(iq(|`m(\iqd{~(~mx{~|(o{zb~{z|(a}m(|`i|(.c{(~ac`|(|{(|`m(`mi~|({b(|`a(c{rm~zemz|(icmzli(izl(~ac`|(|{(|`m(`mi~|({b({}~(rid}m(i(i(xm{xdm.:E~(Eiq(sadd(iq6(.A(ie(odmi~(|`i|(|`a(c{rm~zemz|(sadd(io|(|{(mz}~m(|`i|(|`m(az|m~m|({b(mexd{qmm({z(|~ila|a{zid(o{z|~io|$(|`m(mdb%mexd{qml(izl(|`{m(xm{xdm(s{~gazc(az(|`m(cac(mo{z{eq(i~m(idd(x~{xm~dq(x~{|mo|ml:.'
DECLARE @Counter INT = 1
DECLARE @TempText VARCHAR(MAX) = @text
DECLARE @Character CHAR(5)
DECLARE @Frequency INT
DECLARE @Space CHAR(1)

SET @Space = (SELECT character FROM #CharacterFrequency WHERE PredictedCharacter = ' ')

WHILE DATALENGTH(@Text) >= @Counter
BEGIN
SET @Character = SUBSTRING(@TempText, @Counter,5)
IF @Character LIKE (@Space + '___' + @Space)
BEGIN
IF NOT EXISTS (SELECT 1 FROM #CharacterFrequency WHERE Character = @Character)
BEGIN
SET @frequency = (DATALENGTH(@TempText) - DATALENGTH(REPLACE(@TempText,@Character,''))) / 3
INSERT INTO #CharacterFrequency(Character,Frequency)
VALUES(@Character,@frequency)
END
SET @TempText = @text
END
SET @Counter = @Counter + 1
END



SELECT * 
FROM #CharacterFrequency
WHERE LEN(character) > 1
ORDER BY frequency DESC


--we know that the most common three letter work is 'the' so let's update our frequency table

UPDATE #CharacterFrequency
SET PredictedCharacter = 't'
WHERE Character = SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) > 1 ORDER BY Frequency DESC),2,1)

UPDATE #CharacterFrequency
SET PredictedCharacter = 'h'
WHERE Character = SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) > 1 ORDER BY Frequency DESC),3,1)

UPDATE #CharacterFrequency
SET PredictedCharacter = 'e'
WHERE Character = SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) > 1 ORDER BY Frequency DESC),4,1)



--we also know that the most common three letter word beginning with 'a' is 'and'

DECLARE @a CHAR(1)
SELECT @a = character FROM #CharacterFrequency WHERE PredictedCharacter = 'a'

UPDATE #CharacterFrequency
SET PredictedCharacter = 'n'
WHERE Character = (SELECT SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) > 1 AND Character LIKE ('_' + @a + '___') ORDER BY Frequency DESC),3,1))

UPDATE #CharacterFrequency
SET PredictedCharacter = 'd'
WHERE Character = (SELECT SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) > 1 AND Character LIKE ('_' + @a + '___') ORDER BY Frequency DESC),4,1))





DELETE FROM #CharacterFrequency WHERE LEN(character) > 1


SELECT * 
FROM #CharacterFrequency
ORDER BY FrequencyRank 


--When you know 't' you should be able to find 'to' and therefore identify 'o'
--When you know 'n' and 't' we can hunt for 'it' and 'in' to identify 'i'


--lets analyse two letter words


DECLARE @Text VARCHAR(MAX) = '\`m(i}|`{~({b(i(c{rm~zemz|(~mrams(az|{(s{~g(x~io|aom(a(oiddazc(b{~(|`m(mzl({b(|`m(.oi`(az(`izl(mo{z{eq.:Ei||`ms(\iqd{~$(s`{m(~mx{~|(a({}|({z(\}mliq$(ial(oi`(f{n(dagm(sazl{s(odmizazc(izl(lmo{~i|azc(sm~m(s{~|`(}x(|{(¯2nz(i(qmi~$(e}o`({b(a|(}z|ipml:Az|mil$(|`m(s{~g(`{}dl(nm(xial(|`~{}c`(.xiqemz|(xdi|b{~e.$(E~(\iqd{~(|{dl(NNO(mo{z{eao(mla|{~(Gieid(I`eml:\`m(~mrams$(o{eeaa{zml(nq(\`m~mi(Eiq$(id{(|iogdm(d{s%xial(s{~g$(vm~{(`{}~(o{z|~io|(izl(|`m(cac(mo{z{eq:E~(\iqd{~$(s`{(a(o`amb(mpmo}|arm({b(|`m(^{qid(_{oam|q({b(I~|(izl(i(b{~em~(\{zq(Ndia~(ilra{~$(a(m|(|{(oidd(b{~(oi`(f{n(|{(nm(xial(|`~{}c`(xdi|b{~e(}o`(i(o~mla|(oi~l$(o{z|io|dm(xiqemz|(izl(XiqXid:\`a(s{}dl(eigm(a|(`i~lm~(b{~(o}|{em~(izl(s{~gm~(|{(ir{al(xiqazc(|ip:X~{xm~dq(x~{|mo|ml\`m(~mo{eemzli|a{z(i~m(xi~|({b(i(e}o`(salm~(~mrams(az|{(e{lm~z(s{~gazc(x~io|aom$(azod}lazc(|`m(cac(mo{z{eq:E~(\iqd{~(~mx{~|(~mo{eemzl(i(zms(oi|mc{~q({b(s{~gm~(oiddml(i(.lmxmzlmz|(o{z|~io|{~.$(s`{(`{}dl(nm(carmz(mp|~i(x~{|mo|a{z(nq(ba~e(dagm(]nm~(izl(Lmdarm~{{:A|(id{(iq(d{s%xial(s{~gm~(`{}dl(z{|(nm(.|}og.(i|(|`m(eazae}e(darazc(sicm({~(biom(azmo}~a|q:Eazae}e(sicm(x}`(b{~(cac(mo{z{eq(s{~gm~Lmdarm~{{(e{rm({z(nmzmba|(b{~(~alm~S`i|(a(|`m(cac(mo{z{eqK_xmigazc(i|(a|(di}zo`$(|`m(x~aem(eaza|m~(sadd(iq(|`m(\iqd{~(~mx{~|(o{zb~{z|(a}m(|`i|(.c{(~ac`|(|{(|`m(`mi~|({b(|`a(c{rm~zemz|(icmzli(izl(~ac`|(|{(|`m(`mi~|({b({}~(rid}m(i(i(xm{xdm.:E~(Eiq(sadd(iq6(.A(ie(odmi~(|`i|(|`a(c{rm~zemz|(sadd(io|(|{(mz}~m(|`i|(|`m(az|m~m|({b(mexd{qmm({z(|~ila|a{zid(o{z|~io|$(|`m(mdb%mexd{qml(izl(|`{m(xm{xdm(s{~gazc(az(|`m(cac(mo{z{eq(i~m(idd(x~{xm~dq(x~{|mo|ml:.'
DECLARE @Counter INT = 1
DECLARE @TempText VARCHAR(MAX) = @text
DECLARE @Character CHAR(4)
DECLARE @Frequency INT
DECLARE @Space CHAR(1)

SET @Space = (SELECT character FROM #CharacterFrequency WHERE PredictedCharacter = ' ')

WHILE DATALENGTH(@Text) >= @Counter
BEGIN
SET @Character = SUBSTRING(@TempText, @Counter,5)
IF @Character LIKE (@Space + '__' + @Space)
BEGIN
IF NOT EXISTS (SELECT 1 FROM #CharacterFrequency WHERE Character = @Character)
BEGIN
SET @frequency = (DATALENGTH(@TempText) - DATALENGTH(REPLACE(@TempText,@Character,''))) / 3
INSERT INTO #CharacterFrequency(Character,Frequency)
VALUES(@Character,@frequency)
END
SET @TempText = @text
END
SET @Counter = @Counter + 1
END



SELECT * 
FROM #CharacterFrequency
WHERE LEN(character) > 1




--lets hunt for 'to' should be the most common two letter works beginning with 't'

DECLARE @t CHAR(1)
SELECT @t = character FROM #CharacterFrequency WHERE PredictedCharacter = 't'

SELECT Character FROM #CharacterFrequency WHERE LEN(Character) > 1 AND Character LIKE ('_' + @t + '__') ORDER BY Frequency DESC

UPDATE #CharacterFrequency
SET PredictedCharacter = 'o'
WHERE Character = (SELECT SUBSTRING((SELECT TOP 1 Character FROM #CharacterFrequency WHERE LEN(Character) > 1 AND Character LIKE ('_' + @t + '__') ORDER BY Frequency DESC),3,1))





SELECT * FROM #CharacterFrequency
ORDER BY FrequencyRank ASC



--When you know 'n' and 't' we can hunt for 'it' and 'in' to identify 'i'

DECLARE @t CHAR(1)
DECLARE @n CHAR(1)
SELECT @t = character FROM #CharacterFrequency WHERE PredictedCharacter = 't'
SELECT @n = character FROM #CharacterFrequency WHERE PredictedCharacter = 'n'

SELECT @t AS 'T', @n AS 'N'
SELECT Character, frequency FROM #CharacterFrequency WHERE LEN(Character) > 1 AND (Character LIKE ('__' + @t + '_') OR Character LIKE ('__' + @n + '_')) ORDER BY Frequency DESC




--lets update our frequency table with 'i' (we'll do with one with a simple statement, I idn't get around to writing something fancy for it)


UPDATE #CharacterFrequency
SET PredictedCharacter = 'i'
WHERE Character = 'a'



DELETE FROM #CharacterFrequency WHERE LEN(character) > 1




SELECT * FROM #CharacterFrequency
ORDER BY FrequencyRank ASC
GO










--now that we've got a good number of the most common letters indentifed, we can probabaly start making some good guesses at the rest
--lets see what our known plain text is looking like at the moment

DECLARE @CypherText VARCHAR(MAX) = '\`m(i}|`{~({b(i(c{rm~zemz|(~mrams(az|{(s{~g(x~io|aom(a(oiddazc(b{~(|`m(mzl({b(|`m(.oi`(az(`izl(mo{z{eq.:Ei||`ms(\iqd{~$(s`{m(~mx{~|(a({}|({z(\}mliq$(ial(oi`(f{n(dagm(sazl{s(odmizazc(izl(lmo{~i|azc(sm~m(s{~|`(}x(|{(¯2nz(i(qmi~$(e}o`({b(a|(}z|ipml:Az|mil$(|`m(s{~g(`{}dl(nm(xial(|`~{}c`(.xiqemz|(xdi|b{~e.$(E~(\iqd{~(|{dl(NNO(mo{z{eao(mla|{~(Gieid(I`eml:\`m(~mrams$(o{eeaa{zml(nq(\`m~mi(Eiq$(id{(|iogdm(d{s%xial(s{~g$(vm~{(`{}~(o{z|~io|(izl(|`m(cac(mo{z{eq:E~(\iqd{~$(s`{(a(o`amb(mpmo}|arm({b(|`m(^{qid(_{oam|q({b(I~|(izl(i(b{~em~(\{zq(Ndia~(ilra{~$(a(m|(|{(oidd(b{~(oi`(f{n(|{(nm(xial(|`~{}c`(xdi|b{~e(}o`(i(o~mla|(oi~l$(o{z|io|dm(xiqemz|(izl(XiqXid:\`a(s{}dl(eigm(a|(`i~lm~(b{~(o}|{em~(izl(s{~gm~(|{(ir{al(xiqazc(|ip:X~{xm~dq(x~{|mo|ml\`m(~mo{eemzli|a{z(i~m(xi~|({b(i(e}o`(salm~(~mrams(az|{(e{lm~z(s{~gazc(x~io|aom$(azod}lazc(|`m(cac(mo{z{eq:E~(\iqd{~(~mx{~|(~mo{eemzl(i(zms(oi|mc{~q({b(s{~gm~(oiddml(i(.lmxmzlmz|(o{z|~io|{~.$(s`{(`{}dl(nm(carmz(mp|~i(x~{|mo|a{z(nq(ba~e(dagm(]nm~(izl(Lmdarm~{{:A|(id{(iq(d{s%xial(s{~gm~(`{}dl(z{|(nm(.|}og.(i|(|`m(eazae}e(darazc(sicm({~(biom(azmo}~a|q:Eazae}e(sicm(x}`(b{~(cac(mo{z{eq(s{~gm~Lmdarm~{{(e{rm({z(nmzmba|(b{~(~alm~S`i|(a(|`m(cac(mo{z{eqK_xmigazc(i|(a|(di}zo`$(|`m(x~aem(eaza|m~(sadd(iq(|`m(\iqd{~(~mx{~|(o{zb~{z|(a}m(|`i|(.c{(~ac`|(|{(|`m(`mi~|({b(|`a(c{rm~zemz|(icmzli(izl(~ac`|(|{(|`m(`mi~|({b({}~(rid}m(i(i(xm{xdm.:E~(Eiq(sadd(iq6(.A(ie(odmi~(|`i|(|`a(c{rm~zemz|(sadd(io|(|{(mz}~m(|`i|(|`m(az|m~m|({b(mexd{qmm({z(|~ila|a{zid(o{z|~io|$(|`m(mdb%mexd{qml(izl(|`{m(xm{xdm(s{~gazc(az(|`m(cac(mo{z{eq(i~m(idd(x~{xm~dq(x~{|mo|ml:.'
DECLARE @PlainText VARCHAR(MAX) = ''
DECLARE @Counter INT = 1

WHILE @Counter < DATALENGTH(@CypherText)
BEGIN
	SELECT @PlainText = @PlainText + ISNULL(PredictedCharacter, '#')
	FROM #CharacterFrequency
	WHERE Character = SUBSTRING(@CypherText, @Counter, 1)

	SET @Counter = @Counter + 1
END

SELECT @PlainText








--------------------------------------------------------------------------------------------------
--Pimped Up XOR Cypher
---------------------------------------------------------------------------------------------------

CREATE OR ALTER PROC [dbo].[EncryptData_PimpedXOR]
(@KEY BIGINT,
@PlainText VARCHAR(MAX))
 
AS
 
BEGIN
 
DECLARE @CypherText VARCHAR(MAX) = ''
DECLARE @Counter INT = 1;
DECLARE @TextBlock CHAR(4);
DECLARE @Block BIGINT = 0;
DECLARE @EncryptedBlock BIGINT = 0;
 
WHILE @Counter <= (DATALENGTH(@PlainText))
BEGIN
 --get next 4 byte block
 SET @TextBlock = SUBSTRING(@PlainText,@Counter, 4)
 
--get ACSII representation of @textblock
 SET @Block = CAST(ASCII(SUBSTRING(@TextBlock,1,1)) AS BIGINT) * 16777216 -- Left shift ASCII code by 3 bytes
 SET @Block = @Block + CAST(ASCII(SUBSTRING(@TextBlock,2,1)) AS BIGINT) * 65536 -- Left shift ASCII code by 2 bytes
 SET @Block = @Block + CAST(ASCII(SUBSTRING(@TextBlock,3,1)) AS BIGINT) * 256 -- Left shift ASCII code by 1 byte
 SET @Block = @Block + CAST(ASCII(SUBSTRING(@TextBlock,4,1)) AS BIGINT)
 
--XOR 4 byte key against block
 SET @EncryptedBlock = @Block ^ @Key
 
--convert encrypted block into string
 SET @TextBlock = CHAR(@EncryptedBlock / 16777216) + CHAR((@EncryptedBlock / 65536) & 255) + CHAR((@EncryptedBlock / 256) & 255) + CHAR((@EncryptedBlock) & 255)
 
-- Build Cypher Text string
 SET @CypherText = @CypherText + @TextBlock
 
SET @Counter = @Counter + 4
END
 
SELECT @CypherText
 
END






--let's see it in action
EXEC EncryptData_PimpedXOR 4027558485, 'AAAA'




EXEC EncryptData_PimpedXOR 4027558485, '±Në'




--Plain text Attack


CREATE OR ALTER PROC [dbo].[Crack_O_Matic]
(@PlainText CHAR(4),
@CypherText CHAR(4))
 
AS
 
BEGIN
 
DECLARE @PlainASCII BIGINT
DECLARE @CypherASCII BIGINT
 
--get ACSII representation of @PlainText
SET @PlainASCII = CAST(ASCII(SUBSTRING(@PlainText,1,1)) AS BIGINT) * 16777216 -- Left shift ASCII code by 3 bytes
SET @PlainASCII = @PlainASCII + CAST(ASCII(SUBSTRING(@PlainText,2,1)) AS BIGINT) * 65536 -- Left shift ASCII code by 2 bytes
SET @PlainASCII = @PlainASCII + CAST(ASCII(SUBSTRING(@PlainText,3,1)) AS BIGINT) * 256 -- Left shift ASCII code by 1 byte
SET @PlainASCII = @PlainASCII + CAST(ASCII(SUBSTRING(@PlainText,4,1)) AS BIGINT)
 
--get ACSII representation of @CypherText
SET @CypherASCII = CAST(ASCII(SUBSTRING(@CypherText,1,1)) AS BIGINT) * 16777216 -- Left shift ASCII code by 3 bytes
SET @CypherASCII = @CypherASCII + CAST(ASCII(SUBSTRING(@CypherText,2,1)) AS BIGINT) * 65536 -- Left shift ASCII code by 2 bytes
SET @CypherASCII = @CypherASCII + CAST(ASCII(SUBSTRING(@CypherText,3,1)) AS BIGINT) * 256 -- Left shift ASCII code by 1 byte
SET @CypherASCII = @CypherASCII + CAST(ASCII(SUBSTRING(@CypherText,4,1)) AS BIGINT)
 
SELECT @PlainASCII ^ @CypherASCII
 
END




--performing a plain text attack

EXEC EncryptData_PimpedXOR 4027558485, 'GroupBy'


--our attacker has managed to get hold of the first four characters of the plain text

EXEC Crack_O_Matic 'Grou', '·}Å '








-------------------------------------------------------------------------------------
--Shift the key
-------------------------------------------------------------------------------------

CREATE OR ALTER PROC [dbo].[EncryptData_MiniDES]
(@KEY BIGINT,
@PlainText VARCHAR(MAX))
 
AS
 
BEGIN
 
DECLARE @CypherText VARCHAR(MAX) = ''
DECLARE @Counter INT = 1;
DECLARE @TextBlock CHAR(4);
DECLARE @Block BIGINT = 0;
DECLARE @EncryptedBlock BIGINT = 0;
DECLARE @Key1 BIGINT = 0;
DECLARE @Key2 BIGINT = 0;
 
--generate keys
SET @Key1 = @Key
 
--left shift the key to form key 2
SET @Key2 = @Key * 2
IF @Key2 > 4294967295 --if MSB was 1, wrap around to the LSB
SET @Key2 = (@Key2 - 4294967296) + 1
 
WHILE @Counter <= (DATALENGTH(@PlainText))
BEGIN
--get next 4 byte block
SET @TextBlock = SUBSTRING(@PlainText,@Counter, 4)
 
--get ACSII representation of @textblock
SET @Block = CAST(ASCII(SUBSTRING(@TextBlock,1,1)) AS BIGINT) * 16777216 -- Left shift ASCII code by 3 bytes
SET @Block = @Block + CAST(ASCII(SUBSTRING(@TextBlock,2,1)) AS BIGINT) * 65536 -- Left shift ASCII code by 2 bytes
SET @Block = @Block + CAST(ASCII(SUBSTRING(@TextBlock,3,1)) AS BIGINT) * 256 -- Left shift ASCII code by 1 byte
SET @Block = @Block + CAST(ASCII(SUBSTRING(@TextBlock,4,1)) AS BIGINT)
 
--begin first round XOR
SET @EncryptedBlock = @Block ^ @Key1
 
--begin second round XOR
SET @EncryptedBlock = @EncryptedBlock ^ @Key2
 
--convert encrypted block into string
SET @TextBlock = CHAR(@EncryptedBlock / 16777216) + CHAR((@EncryptedBlock / 65536) & 255) + CHAR((@EncryptedBlock / 256) & 255) + CHAR((@EncryptedBlock) & 255)
 
-- Build Cypher Text string
SET @CypherText = @CypherText + @TextBlock
 
SET @Counter = @Counter + 4
END
 
SELECT @CypherText
 
END




-----------------------------------------------------------------------------------------------
--to encrypt....
EXEC EncryptData_MiniDES 4027558485, 'GroupBy'


--to decrypt...
EXEC EncryptData_MiniDES 4027558485, 'Wb‘‹`R‡Þ'



--but what about if we try a plain text attack?
EXEC Crack_O_Matic 'Grou', 'Wb‘‹'




--let's try using that key....
EXEC EncryptData_MiniDES 269549310, 'Wb‘‹`R‡Þ'