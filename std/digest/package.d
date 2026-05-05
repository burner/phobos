/**
 * This module describes the digest APIs used in Phobos. All digests follow
 * these APIs. Additionally, this module contains useful helper methods which
 * can be used with every digest type.
 *
$(SCRIPT inhibitQuickIndex = 1;)

$(DIVC quickindex,
$(BOOKTABLE ,
$(TR $(TH Category) $(TH Functions)
)
$(TR $(TDNW Template API) $(TD $(MYREF isDigest) $(MYREF DigestType) $(MYREF hasPeek)
  $(MYREF hasBlockSize)
  $(MYREF ExampleDigest) $(MYREF digest) $(MYREF hexDigest) $(MYREF makeDigest)
)
)
$(TR $(TDNW OOP API) $(TD $(MYREF Digest)
)
)
$(TR $(TDNW Helper functions) $(TD $(MYREF toHexString) $(MYREF secureEqual))
)
$(TR $(TDNW Implementation helpers) $(TD $(MYREF digestLength) $(MYREF WrapperDigest))
)
)
)

 * APIs:
 * There are two APIs for digests: The template API and the OOP API. The template API uses structs
 * and template helpers like $(LREF isDigest). The OOP API implements digests as classes inheriting
 * the $(LREF Digest) interface. All digests are named so that the template API struct is called "$(B x)"
 * and the OOP API class is called "$(B x)Digest". For example we have `MD5` <--> `MD5Digest`,
 * `CRC32` <--> `CRC32Digest`, etc.
 *
 * The template API is slightly more efficient. It does not have to allocate memory dynamically,
 * all memory is allocated on the stack. The OOP API has to allocate in the finish method if no
 * buffer was provided. If you provide a buffer to the OOP APIs finish function, it doesn't allocate,
 * but the $(LREF Digest) classes still have to be created using `new` which allocates them using the GC.
 *
 * The OOP API is useful to change the digest function and/or digest backend at 'runtime'. The benefit here
 * is that switching e.g. Phobos MD5Digest and an OpenSSLMD5Digest implementation is ABI compatible.
 *
 * If just one specific digest type and backend is needed, the template API is usually a good fit.
 * In this simplest case, the template API can even be used without templates: Just use the "$(B x)" structs
 * directly.
 *
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:
 * Johannes Pfau
 *
 * Source:    $(PHOBOSSRC std/digest/package.d)
 *
 * CTFE:
 * Digests do not work in CTFE
 *
 * TODO:
 * Digesting single bits (as opposed to bytes) is not implemented. This will be done as another
 * template constraint helper (hasBitDigesting!T) and an additional interface (BitDigest)
 */
/*          Copyright Johannes Pfau 2012.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module std.digest;
public import std.digest.digest;
