#!/usr/bin/env python3

from ete3 import NCBITaxa
from queue import Queue
from threading import Thread


tax_ranks = (
    "superkingdom", "kingdom", "phylum", "subphylum", "class", "subclass", "order", "family", "genus", "species")


class Worker(Thread):
    """ Thread executing tasks from a given tasks queue """
    def __init__(self, tasks):
        Thread.__init__(self)
        self.tasks = tasks
        self.daemon = True
        self.start()

    def run(self):
        while True:
            func, args, kargs = self.tasks.get()
            try:
                func(*args, **kargs)
            # except Exception as e:
            #     # An exception happened in this thread
            #     print(e)
            except:
                raise
            finally:
                # Mark this task as done, whether an exception happened or not
                self.tasks.task_done()


class ThreadPool(object):
    """ Pool of threads consuming tasks from a queue """
    def __init__(self, num_threads):
        self.tasks = Queue(num_threads)
        for _ in range(num_threads):
            Worker(self.tasks)

    def add_task(self, func, *args, **kargs):
        """ Add a task to the queue """
        self.tasks.put((func, args, kargs))

    def map(self, func, args_list):
        """ Add a list of tasks to the queue """
        for args in args_list:
            self.add_task(func, args)

    def wait_completion(self):
        """ Wait for completion of all the tasks in the queue """
        self.tasks.join()


def get_bin(taxrank, record_id, fqids):
    """
    Returns the name of the taxonomic clade closest to the given rank where the given TaxID falls under.
    """
    taxdb = NCBITaxa()
    lineage = [1]
    try:
        lineage = taxdb.get_lineage(fqids[record_id])[::-1]  # bottleneck for the script
    except ValueError:
        #       logging.warning("Taxonomy ID %s not found" % taxonomy_id) # Generates a LOT of noise in the logs
        fqids[record_id] = "root"
        return
    ranks = taxdb.get_rank(lineage)
    target = tax_ranks.index(taxrank)
    for clade in lineage:
        try:
            idx = tax_ranks.index(ranks[clade])
        except ValueError:
            continue
        if idx == target:
            fqids[record_id] = taxdb.get_taxid_translator([clade])[clade].lower()
            return
    fqids[record_id] = "root"


if __name__ == "__main__":
    # Test lineage lookup
    fqids_normal = {
        "READ:001": 9606,
        "READ:002": 6433,
        "READ:003": 1234,
        "READ:004": 7654
    }
    for fqid in fqids_normal:
        get_bin("phylum", fqid, fqids_normal)
    print(fqids_normal)
    # Test threading
    fqids_threaded = {
        "READ:001": 9606,
        "READ:002": 6433,
        "READ:003": 1234,
        "READ:004": 7654
    }
    lineage_pool = ThreadPool(4)
    for fqid in fqids_threaded:
        lineage_pool.add_task(get_bin, "phylum", fqid, fqids_threaded)
    lineage_pool.wait_completion()
    print(fqids_threaded)

    assert fqids_normal == fqids_threaded
