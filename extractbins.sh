#!/bin/env bash
#
# Cisco Image file extractor - daniel webster.
#
# This is unfinished - use at your own risk.
#
# ** THE CONTENT HEREIN HAS NOTHING TO DO WITH MY EMPLOYER **
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

version=1.1

function usage()
{
	die "$0: [file.bin] [directory_to_extract_to]"
}

function info()
{
	echo "[.] $@"
}

function die()
{
	echo "$@"
	exit 1
}

function hex2dec()
{
	hex=$1
	printf "%d" 0x$hex
}

function xb()
{
	local file=$1
	local from=$2
	local to=$3
	local seek=${4:-0}
	echo $(xxd -seek $seek -p $file | head -1 | cut -b${from}-${to})
}

function strip_hdr()
{
	local file=$1
	local len=$2
	info "seeking past header length $len...."
	dd if=$file of=${file}.nohdr bs=$len skip=1 >/dev/null 2>&1
	info "wrote header-less image ${file}.nohdr"
}

function filetype()
{
	local file=$1
	local magic=$2
	local magic_pos_from=$3
	local magic_pos_to=$4
	local seek=${5:-0}
	if [[ "$(xb ${file} $magic_pos_from $magic_pos_to $seek)" != "$magic" ]]; then
		echo 0
	else
		echo 1
	fi
}

function is_cisco()
{
	local file=$1
	local cisco_magic="534e"
	local cisco_magic_pos=(5 8)
	echo $(filetype $file $cisco_magic ${cisco_magic_pos[@]})
}

function is_gzip()
{
	local file=$1
	local gzip_magic="1f8b08"
	local gzip_magic_pos=(1 6)
	echo $(filetype $file $gzip_magic ${gzip_magic_pos[@]})
}

function is_tar()
{
	local file=$1
	local tar_magic="7573746172"
	local tar_magic_pos=(1 10)
	local tar_seek=257
	echo $(filetype $file $tar_magic ${tar_magic_pos[@]} $tar_seek)
}

function is_cpio()
{
	local file=$1
	# XXX: don't forget 677[01]
	local cpio_magic="070701"
}

function is_nbi()
{
	local file=$1
	local nbi_magic="3613031b"
	local nbi_magic_pos=(1 8)
	echo $(filetype $file $nbi_magic ${nbi_magic_pos[@]})
}

function is_elf()
{
	local file=$1
	local elf_magic="7f454c46"
}

function hdr_len()
{
	local file=$1
	local hdr_len_pos=(9 12)
	echo $(hex2dec "$(xb $file ${hdr_len_pos[@]})")
}

# Entry
echo "cisco image extractor $version - dsw(c),2017"
if [[ "$#" != "2" ]]; then
	usage
fi
file=$1
dir=$2

if [[ ! -d $dir ]]; then
	die "$dir does not exist - will not create it.."
fi

if [[ "$(is_cisco $file)" == "1" ]]; then
	len=$(hdr_len $file)
	info "cisco image of $len bytes found in $file"
elif [[ "$(is_nbi $file)" == "1" ]]; then
	# Hardcode to MBR len
	len=512
	die "DOS/MBR/NBI (possible kickstart) found in $file - not supported."

else
	die "$file is not a cisco image, nor NBI/kickstart."
fi

strip_hdr $file $len
file=${file}.nohdr

if [[ "$(is_gzip $file)" == "1" ]]; then
	info "gzip found; decompressing.."
	mv ${file} ${file}.gz && gunzip ${file}.gz
	if [[ "$(is_tar $file)" == "1" ]]; then
		info "tar found; untarring.."
		tar -C $dir -xvf $file && rm $file
		info "cleaning up.."
	elif [[ "$(is_elf $file)" == "1" ]]; then
		info "ELF file (probably kernel) found.. skipping."
	else
		test -f ${file} && rm ${file}
		die "no tar file found."
	fi
else
	test -f ${file} && rm ${file}
	die "no gzip file found."
fi

info "done"
